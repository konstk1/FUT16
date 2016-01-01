//
//  AutoTrader.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 12/21/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation

// TODO: Auto pause
// TODO: Display account ballance
// TODO: Request count (per day)
// TOOD: If error multiple times in a row, stop trading
// TODO: Auto-increment max price (starting from BIN)
// TODO: Search by league, team, nationality

class AutoTrader: NSObject {
    private var fut16: FUT16
    private var playerId = ""
    private var maxSearchBin: UInt = 0
    private var buyAtBin: UInt = 0
    
    var pollingInterval: NSTimeInterval = 3.0
    private var pollTimer: NSTimer!
    
    init(fut16: FUT16) {
        self.fut16 = fut16
    }
    
    // return break-even buy
    func setTradeParams(playerId: String, maxSearchBin: UInt, buyAtBin: UInt) -> UInt {
        guard buyAtBin <= maxSearchBin else {
            print("Buy BIN is more than search BIN!")
            stopTrading()
            return 0
        }
        
        self.playerId = playerId
        self.maxSearchBin = maxSearchBin
        self.buyAtBin = buyAtBin
        
        print("Trade params: \(playerId) - search <= \(self.maxSearchBin) - buy at <= \(self.buyAtBin)")
        
        let breakEvenPrice = UInt(round(Double(maxSearchBin) * 0.95))
        return breakEvenPrice
    }
    
    func startTrading() {
        pollAuctions()
        pollTimer = NSTimer.scheduledTimerWithTimeInterval(pollingInterval, target: self, selector: Selector("pollAuctions"), userInfo: nil, repeats: true)
    }
    
    func stopTrading() {
        if pollTimer.valid {
            pollTimer.invalidate()
        }
        searchCount = 0     // reset search count
        
        print("Trading stopped.")
    }
    
    private var minBin: UInt = 10000000
    private var searchCount = 0
    
    func pollAuctions() {
        print(".", terminator: "")
        var curMinBin: UInt = 10000000
        var curMinId: String = ""
        
        fut16.findBinForPlayerId(playerId, maxBin: maxSearchBin) { (auctions) -> Void in
            auctions.forEach({ (id, bin) -> () in
                if let curBin = UInt(bin) {
                    if curBin < curMinBin {
                        curMinBin = curBin
                        curMinId = id
                    }
                }
            })
            
            if curMinBin <= self.buyAtBin {
                print("Purchasing...")
                self.fut16.placeBidOnAuction(curMinId, ammount: curMinBin)
            }
            
            if curMinBin < self.minBin {
                self.minBin = curMinBin
            }
            
            self.searchCount++
            print("Search: \(self.searchCount) (\(auctions.count)) - Cur Min: \(curMinBin) (Min: \(self.minBin))")
        }
    }

    
}