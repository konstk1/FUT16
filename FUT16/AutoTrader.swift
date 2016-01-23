//
//  AutoTrader.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 12/21/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import Cocoa

// TODO: Auto price update (BIN and purchase)
// TODO: Auto move to transfer list
// TODO: Fetch data on background thread

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
            return Search.numSearchesSinceDate(NSDate.hourAgo, managedObjectContext: managedObjectContext)
        }
    }
    var searchCount90min: Int {
        get {
            return 0//Search.numSearchesSinceDate(NSDate(timeIntervalSinceNow: -60*90), managedObjectContext: managedObjectContext)
        }
    }
    var searchCount2Hr: Int {
        get {
            return 0//Search.numSearchesSinceDate(NSDate(timeIntervalSinceNow: -2*3600), managedObjectContext: managedObjectContext)
        }
    }
    var searchCount24Hr: Int {
        get {
            return Search.numSearchesSinceDate(NSDate.dayAgo, managedObjectContext: managedObjectContext)
        }
    }
    
    var searchCountAllTime: Int {
        get {
            return Search.numSearchesSinceDate(NSDate.allTime, managedObjectContext: managedObjectContext)
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
    private var itemParams: FUT16.ItemParams!
    private var buyAtBin: UInt = 0
    
    private var sessionErrorCount = 0
    private let SESSION_ERROR_LIMIT = 3      // stop trading after this many session errors
    private let SEARCH_LIMIT_1HR = 950       // stop trading after this many searching within 1 hour
    
    var pollingInterval: NSTimeInterval = 1.2 //2.0
    private var pollTimer: NSTimer!
    
    private(set) public var minBin: UInt = 10000000
    
    private var purchaseQueue = Array<FUT16.AuctionInfo>()
    
    private(set) public var stats = TraderStats()
    
    private var updateOwner: (() -> ())?
    
    private var activity: NSObjectProtocol!      // activity to disable app nap
    
    public init(fut16: FUT16, update: (() -> ())?) {
        self.fut16 = fut16
        self.updateOwner = update
        //notifyOwner()
    }
    
    // return break-even buy
    func setTradeParams(itemParams: FUT16.ItemParams, buyAtBin: UInt) -> UInt {
        guard buyAtBin <= itemParams.maxBin else {
            stopTrading("Buy BIN is more than search BIN")
            return 0
        }

        self.itemParams = itemParams
        self.itemParams.maxPrice = itemParams.maxBin
        self.buyAtBin = buyAtBin
        
        print("Trade params: \(self.itemParams.type) - search <= \(self.itemParams.minBin)-\(self.itemParams.maxBin) - buy at <= \(self.buyAtBin)")
        
        let breakEvenPrice = UInt(round(Double(itemParams.maxBin) * 0.95))
        return breakEvenPrice
    }
    
    func resetStats() {
        stats = TraderStats()
        sessionErrorCount = 0
        minBin = 10000000
        notifyOwner()
    }
    
    func startTrading() {
        // do nothing if timer is already running
        if (pollTimer == nil || !pollTimer.valid) {
            pollAuctions()
            pollTimer = NSTimer.scheduledTimerWithTimeInterval(pollingInterval, target: self, selector: Selector("pollAuctions"), userInfo: nil, repeats: true)
        }
        
        // disable app nap
        activity = NSProcessInfo().beginActivityWithOptions(.UserInitiated, reason: "FUT Trading")
    }
    
    func stopTrading(reason: String) {
        if pollTimer != nil && pollTimer.valid {
            pollTimer.invalidate()
        }
        
        self.notifyOwner()
        
        print("Trading stopped: [\(reason)].")
        
        // re-enable app nap
        if activity != nil {
            NSProcessInfo().endActivity(activity)
            activity = nil
        }
        
        fut16.sendItemsToTransferList()
    }
    
    func pollAuctions() {
        print(".\(NSDate.localTime):  ", terminator: "")
        var curMinBin: UInt = 10000000
        
        // increment max price to avoid cached results
        itemParams.maxPrice = incrementPrice(itemParams.maxPrice)
        
        fut16.findAuctionsForItem(itemParams) { (auctions, error) -> Void in
            self.stats.searchCount++
            self.logSearch()        // save to CoreData
            
            self.stats.coinsBalance = self.fut16.coinsBalance   // grab coins ballance
            
            if self.stats.searchCount1Hr >= self.SEARCH_LIMIT_1HR {
                self.stopTrading("Search limit reached")
            }
            
            // check for errors
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
            
            // find current search min bins
            auctions.forEach {
                if $0.buyNowPrice < curMinBin {
                    curMinBin = $0.buyNowPrice
                }
                
                if $0.buyNowPrice <= self.buyAtBin && $0.isRare {
                    self.purchaseQueue.append($0)
                    print("Purchase Queued \($0.tradeId)")
                }
            }
            
            print("Search: \(self.stats.searchCount) (\(auctions.count)-\(self.itemParams.startRecord)) - Cur Min: \(curMinBin) (Min: \(self.minBin)) - \(self.itemParams.maxPrice)")
            
            // update session min
            if curMinBin < self.minBin {
                self.minBin = curMinBin
            }
            
            self.processPurchaseQueue()
            self.tuneSearchParamsFromAuctions(auctions)
            
            self.notifyOwner()
        } // findAuctionsForPlayer
    } // end pollAuctions
    
    func tuneSearchParamsFromAuctions(auctions: [FUT16.AuctionInfo]) {
        // at the moment, tune start page only
        // find page that has newly listed auctions (as close to but less than 1hr - 3600 seconds)
//        print("Tune: start \(itemParams.startRecord): \(auctions.first?.expiresIn) - \(auctions.last?.expiresIn)")

        if auctions.isEmpty {
            // if empty, back off one page but don't go past 0
            if itemParams.startRecord < itemParams.numRecords {
                itemParams.startRecord = 0
            } else {
                itemParams.startRecord -= itemParams.numRecords
            }
        } else if auctions.count < Int(itemParams.numRecords) {
            // if there is less then a single page of auctions, do nothing
            return
        } else if auctions.last?.expiresIn < 3600 {
            itemParams.startRecord += itemParams.numRecords
        } else if auctions.first?.expiresIn >= 3600 {
            itemParams.startRecord -= itemParams.numRecords
        }
    }
    
    var currentAuction: FUT16.AuctionInfo!
    
    func processPurchaseQueue() {
        guard purchaseQueue.count > 0 else { return }
        
        let auction = purchaseQueue.removeFirst()
        
        print("Purchasing \(auction.tradeId) (\(auction.buyNowPrice))...", terminator: "")
        self.fut16.placeBidOnAuction(auction.tradeId, amount: auction.buyNowPrice) { (error) in
            defer {
                NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("processPurchaseQueue"), userInfo: nil, repeats: false)
            }
            guard error == .None else {
                print("Fail: Error - \(error).")
                self.stats.purchaseFailCount++
                return
            }
            
            // some stat keeping
            self.stats.purchaseCount++
            self.stats.lastPurchaseCost = Int(auction.buyNowPrice)
            self.stats.purchaseTotalCost += self.stats.lastPurchaseCost
            self.stats.coinsBalance = self.fut16.coinsBalance
            self.stats.averagePurchaseCost = Int(round(Double(self.stats.purchaseTotalCost) / Double(self.stats.purchaseCount)))
            
            // save to CoreData
            Purchase.NewPurchase(Int(auction.buyNowPrice), maxBin: Int(self.itemParams.maxBin), coinBallance: self.fut16.coinsBalance, managedObjectContext: managedObjectContext)
            
            print("Success!")
            
            // stop trading if not enough coins for next purchase
            if self.fut16.coinsBalance < Int(self.buyAtBin) {
                self.stopTrading("Not enough coins.  Balance: \(self.fut16.coinsBalance)")
            }
            
            // FUT only allows 5 unassigned players
            if self.stats.purchaseCount >= 5 {
                self.stopTrading("Unassigned slots full")
            }
        }
        self.notifyOwner()
    }
    
    func notifyOwner() {
        self.updateOwner?()
    }
    
// MARK: Stat and CoreData helpers
    func logSearch() {
        Search.NewSearch(managedObjectContext: managedObjectContext)
    }
}