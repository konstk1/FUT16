//
//  AutoTrader.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 12/21/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import Cocoa

// TODO: Get user info (coins) on login

private let managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

public class TraderStats: NSObject {
    var searchCount = 0
    
    var purchaseCount = 0
    var purchaseFailCount = 0
    var purchaseTotalCost = 0
    
    var averagePurchaseCost = 0
    var lastPurchaseCost = 0
    var coinsBalance = 0
    
    var searchCount1Hr: Int {
        get {
            return Search.getSearchesSinceDate(NSDate.hourAgo, managedObjectContext: managedObjectContext).count
        }
    }
    var searchCount90min: Int {
        get {
            return Search.getSearchesSinceDate(NSDate(timeIntervalSinceNow: -60*90), managedObjectContext: managedObjectContext).count
        }
    }
    var searchCount2Hr: Int {
        get {
            return Search.getSearchesSinceDate(NSDate(timeIntervalSinceNow: -2*3600), managedObjectContext: managedObjectContext).count
        }
    }
    var searchCount24Hr: Int {
        get {
            return Search.getSearchesSinceDate(NSDate.dayAgo, managedObjectContext: managedObjectContext).count
        }
    }
    
    var searchCountAllTime: Int {
        get {
            return Search.getSearchesSinceDate(NSDate.allTime, managedObjectContext: managedObjectContext).count
        }
    }
    
    var purchaseTotalAllTime: Int {
        get {
            let purchases = Purchase.getPurchasesSinceDate(NSDate.allTime, managedObjectContext: managedObjectContext)
            return Int(purchases.reduce(0) { $0 + $1.price })
        }
    }
}

public class AutoTrader: NSObject {
    private var fut16: FUT16
    private var playerParams = FUT16.PlayerParams()
    private var buyAtBin: UInt = 0
    
    private var sessionErrorCount = 0
    private let SESSION_ERROR_LIMIT = 3      // stop trading after this many session errors
    private let SEARCH_LIMIT_1HR = 950       // stop trading after this many searching within 1 hour
    
    var pollingInterval: NSTimeInterval = 2.0
    private var pollTimer: NSTimer!
    
    private(set) public var minBin: UInt = 10000000
    
    private(set) public var stats = TraderStats()
    
    private var updateOwner: (() -> ())?
    
    public init(fut16: FUT16, update: (() -> ())?) {
        self.fut16 = fut16
        self.updateOwner = update
        //updateOwner?()
    }
    
    // return break-even buy
    func setTradeParams(playerParams: FUT16.PlayerParams, buyAtBin: UInt) -> UInt {
        guard buyAtBin <= playerParams.maxBin else {
            stopTrading("Buy BIN is more than search BIN")
            return 0
        }

        self.playerParams = playerParams
        self.playerParams.maxPrice = playerParams.maxBin
        self.buyAtBin = buyAtBin
        
        print("Trade params: \(self.playerParams.playerId) - search <= \(self.playerParams.maxBin) - buy at <= \(self.buyAtBin)")
        
        let breakEvenPrice = UInt(round(Double(playerParams.maxBin) * 0.95))
        return breakEvenPrice
    }
    
    func resetStats() {
        stats = TraderStats()
        sessionErrorCount = 0
        minBin = 10000000
        updateOwner?()
    }
    
    func startTrading() {
        // do nothing if timer is already running
        if (pollTimer == nil || !pollTimer.valid) {
            pollAuctions()
            pollTimer = NSTimer.scheduledTimerWithTimeInterval(pollingInterval, target: self, selector: Selector("pollAuctions"), userInfo: nil, repeats: true)
        }
    }
    
    func stopTrading(reason: String) {
        if pollTimer != nil && pollTimer.valid {
            pollTimer.invalidate()
        }
        
        fut16.getUserInfo()
        self.updateOwner?()
        
        print("Trading stopped: [\(reason)].")
    }
    
    func pollAuctions() {
        print(".\(NSDate.localTime):  ", terminator: "")
        var curMinBin: UInt = 10000000
        var curMinId: String = ""
        
        // increment max price to avoid cached results
        playerParams.maxPrice = incrementPrice(playerParams.maxPrice)
        
        fut16.findAuctionsForPlayer(playerParams) { (auctions, error) -> Void in
            self.stats.searchCount++
            self.logSearch()        // save to CoreData
            
            self.stats.coinsBalance = self.fut16.coinsBalance   // grab coins ballance
            
            if self.stats.searchCount1Hr >= self.SEARCH_LIMIT_1HR {
                self.stopTrading("Search limit reached")
            }
            
            // anything but 
            guard error == .None else {
                print(error)
                self.sessionErrorCount++
                if self.sessionErrorCount < self.SESSION_ERROR_LIMIT {
                    self.fut16.retrieveSessionId()   // re-login
                } else {
                    self.stopTrading("Session error limit reached")
                }
                return
            }
            
            auctions.forEach({ (id, bin) -> () in
                if let curBin = UInt(bin) {
                    if curBin < curMinBin {
                        curMinBin = curBin
                        curMinId = id
                    }
                }
            })
            
            print("Search: \(self.stats.searchCount) (\(auctions.count)) - Cur Min: \(curMinBin) (Min: \(self.minBin)) - \(self.playerParams.maxPrice)")
            
            if curMinBin <= self.buyAtBin {
                print("Purchasing...", terminator: "")
                self.fut16.placeBidOnAuction(curMinId, ammount: curMinBin) { (error) in
                    guard error == .None else {
                        print("Fail: Error - \(error).")
                        self.stats.purchaseFailCount++
                        return
                    }
                    
                    // some stat keeping
                    self.stats.purchaseCount++
                    self.stats.lastPurchaseCost = Int(curMinBin)
                    self.stats.purchaseTotalCost += self.stats.lastPurchaseCost
                    self.stats.coinsBalance = self.fut16.coinsBalance
                    self.stats.averagePurchaseCost = Int(round(Double(self.stats.purchaseTotalCost) / Double(self.stats.purchaseCount)))
                    
                    // save to CoreData
                    Purchase.NewPurchase(Int(curMinBin), maxBin: Int(self.playerParams.maxBin), coinBallance: self.fut16.coinsBalance, managedObjectContext: managedObjectContext)
                    
                    print("Success!")
                    
                    if self.fut16.coinsBalance < Int(self.buyAtBin) {
                        self.stopTrading("Not enough coins.  Balance: \(self.fut16.coinsBalance)")
                    }
                    
                    // FUT only allows 5 unassigned players
                    if self.stats.purchaseCount >= 5 {
                        self.stopTrading("Unassigned slots full")
                    }
                }
                self.updateOwner?()
            }
            
            if curMinBin < self.minBin {
                self.minBin = curMinBin
            }
            
            self.updateOwner?()
        } // findAuctionsForPlayer
    } // end pollAuctions
    
// MARK: Stat and CoreData helpers
    func logSearch() {
        Search.NewSearch(managedObjectContext: managedObjectContext)
    }
}