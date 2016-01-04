//
//  AutoTrader.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 12/21/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import Cocoa

// TODO: Request count (per day)
// TOOD: Coin ballance history

public class TraderStats: NSObject {
    var searchCount = 0
    var purchaseCount = 0
    var purchaseFailCount = 0
    var purchaseTotalCost = 0
    var lastPurchaseCost = 0
    var coinsBallance = 0
}

public class AutoTrader: NSObject {
    private var fut16: FUT16
    private var playerParams = FUT16.PlayerParams()
    private var buyAtBin: UInt = 0
    
    private var expiredSessionCount = 0
    private let EXPIRED_SESSIONS_LIMIT = 3      // stop trading after this many expired session errors
    
    var pollingInterval: NSTimeInterval = 2.0
    private var pollTimer: NSTimer!
    
    private(set) public var minBin: UInt = 10000000
    
    private(set) public var stats = TraderStats()
    
    private var updateOwner: (() -> ())?
    
    //private let managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    public init(fut16: FUT16, update: (() -> ())?) {
        self.fut16 = fut16
        self.updateOwner = update
    }
    
    // return break-even buy
    func setTradeParams(playerParams: FUT16.PlayerParams, buyAtBin: UInt) -> UInt {
        guard buyAtBin <= playerParams.maxBin else {
            print("Buy BIN is more than search BIN!")
            stopTrading()
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
        updateOwner?()
    }
    
    func startTrading() {
        pollAuctions()
        pollTimer = NSTimer.scheduledTimerWithTimeInterval(pollingInterval, target: self, selector: Selector("pollAuctions"), userInfo: nil, repeats: true)
    }
    
    func stopTrading() {
        if pollTimer != nil && pollTimer.valid {
            pollTimer.invalidate()
        }
        
        stats.searchCount = 0     // reset search count
        
        print("Trading stopped.")
    }
    
    func pollAuctions() {
        print(".", terminator: "")
        var curMinBin: UInt = 10000000
        var curMinId: String = ""
        
        // increment max price to avoid cached results
        playerParams.maxPrice = incrementPrice(playerParams.maxPrice)
        
        fut16.findAuctionsForPlayer(playerParams) { (auctions, error) -> Void in
            self.stats.searchCount++
            
            guard error != .ExpiredSession else {
                self.expiredSessionCount++
                if self.expiredSessionCount < self.EXPIRED_SESSIONS_LIMIT {
                    self.fut16.retrieveSessionId()   // re-login
                } else {
                    print("Expired sessions limit reached.")
                    self.stopTrading()
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
                    
                    print("Success!")
                    
                    if self.fut16.coinsBallance < Int(self.buyAtBin) {
                        print("Not enough coins.  Ballance: \(self.fut16.coinsBallance)")
                        self.stopTrading()
                    }
                    
                    // FUT only allows 5 unassigned players
                    if self.stats.purchaseCount >= 5 {
                        print("Unassigned slots full.")
                        self.stopTrading()
                    }
                }
            }
            
            if curMinBin < self.minBin {
                self.minBin = curMinBin
            }
            
            self.updateOwner?()
        } // findAuctionsForPlayer
    } // end pollAuctions
    
}