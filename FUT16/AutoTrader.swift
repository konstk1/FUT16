//
//  AutoTrader.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 12/21/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation

// TODO: Display account ballance
// TODO: Request count (per day)
// TOOD: Coin ballance history
// TODO: Auto-increment max price (starting from BIN)

public class AutoTrader: NSObject {
    private var fut16: FUT16
    private var playerParams = FUT16.PlayerParams()
    private var buyAtBin: UInt = 0
    
    private var expiredSessionCount = 0
    private let EXPIRED_SESSIONS_LIMIT = 3      // stop trading after this many expired session errors
    
    var pollingInterval: NSTimeInterval = 3.0
    private var pollTimer: NSTimer!
    
    private(set) public var minBin: UInt = 10000000
    private(set) public var searchCount = 0
    private(set) public var numPurchases = 0
    
    
    public init(fut16: FUT16) {
        self.fut16 = fut16
    }
    
    // return break-even buy
    func setTradeParams(playerParams: FUT16.PlayerParams, buyAtBin: UInt) -> UInt {
        guard buyAtBin <= playerParams.maxBin else {
            print("Buy BIN is more than search BIN!")
            stopTrading()
            return 0
        }

        self.playerParams = playerParams
        self.buyAtBin = buyAtBin
        
        print("Trade params: \(self.playerParams.playerId) - search <= \(self.playerParams.maxBin) - buy at <= \(self.buyAtBin)")
        
        let breakEvenPrice = UInt(round(Double(playerParams.maxBin) * 0.95))
        return breakEvenPrice
    }
    
    func startTrading() {
        playerParams.maxPrice = playerParams.maxBin
        pollAuctions()
        pollTimer = NSTimer.scheduledTimerWithTimeInterval(pollingInterval, target: self, selector: Selector("pollAuctions"), userInfo: nil, repeats: true)
    }
    
    func stopTrading() {
        if pollTimer != nil && pollTimer.valid {
            pollTimer.invalidate()
        }
        searchCount = 0     // reset search count
        
        print("Trading stopped.")
    }
    
    func pollAuctions() {
        print(".", terminator: "")
        var curMinBin: UInt = 10000000
        var curMinId: String = ""
        
        // increment max price to avoid cached results
        playerParams.maxPrice = incrementPrice(playerParams.maxPrice)
        
        fut16.findAuctionsForPlayer(playerParams) { (auctions, error) -> Void in
            self.searchCount++
            
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
            
            print("Search: \(self.searchCount) (\(auctions.count)) - Cur Min: \(curMinBin) (Min: \(self.minBin)) - \(self.playerParams.maxPrice)")
            
            if curMinBin <= self.buyAtBin {
                print("Purchasing...", terminator: "")
                self.fut16.placeBidOnAuction(curMinId, ammount: curMinBin) { (error) in
                    guard error == .None else {
                        print("Fail.")
                        return
                    }
                    self.numPurchases++
                    print("Success!")
                    
                    if self.fut16.coinsBallance < Int(self.buyAtBin) {
                        print("Not enough coins.  Ballance: \(self.fut16.coinsBallance)")
                        self.stopTrading()
                    }
                }
            }
            
            if curMinBin < self.minBin {
                self.minBin = curMinBin
            }
        }
    }

    
}