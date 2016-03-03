//
//  AutoTrader.swift
//  FUT16
//
//  Created by Kon on 12/21/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import Cocoa

// TODO: Fix stats (multi-user)
// TODO: Make timing setting calculate inner timing

private let managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

public class AutoTrader: NSObject {
    private var fut16 = [FUT16]()
    private var currentFut: FUT16
    private var currentFutIdx = 0
    
    private var itemParams: FUT16.ItemParams!
    private var buyAtBin: UInt = 0
    
    private var sessionErrorCount = 0
    private let SESSION_ERROR_LIMIT = 3      // stop trading after this many session errors
    private let SEARCH_LIMIT_1HR = 950       // stop trading after this many searches within 1 hour
    private let SEARCH_LIMIT_24HR = 5300     // stop trading after this many searches within 24 hours
    
    private var pollTimer: NSTimer!
    private var cycleTimer: NSTimer!
    
    enum State {
        case Ready
        case Polling
        case Break
        case Stopped
    }
    
    private var state = State.Ready
    
    private(set) public var minBin: UInt = 10000000
    
    private var purchaseQueue = Array<FUT16.AuctionInfo>()
    
    private(set) public var stats: TraderStats
    private var settings = Settings.sharedInstance
    
    private var updateOwner: (() -> ())?
    
    private var activity: NSObjectProtocol!      // activity to disable app nap
    
    public init(fut16: [FUT16], update: (() -> ())?) {
        self.fut16 = fut16
        currentFut = self.fut16.first!
        
        self.updateOwner = update
        
        stats = TraderStats()
        //notifyOwner()
//        Log.print("Autotrader Init")
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
        
        Log.print("Trade params: \(self.itemParams.type) - search <= \(self.itemParams.minBin)-\(self.itemParams.maxBin) - buy at <= \(self.buyAtBin)")
        
        let breakEvenPrice = UInt(round(Double(itemParams.maxBin) * 0.95))
        return breakEvenPrice
    }
    
    func resetStats() {
        stats = TraderStats()
        sessionErrorCount = 0
        minBin = 10000000
        notifyOwner()
    }
    
    func stopAllTimers() {
        if pollTimer != nil && pollTimer.valid {
            pollTimer.invalidate()
        }
        
        if cycleTimer != nil && cycleTimer.valid {
            cycleTimer.invalidate()
        }
    }
    
    func startTrading() {
        Log.print("State: \(state)")
        if state == .Ready || state == .Stopped {
            cycleStart()
        } else {
            Log.print("Already trading")
        }
        
        // disable app nap
        if activity == nil {
            activity = NSProcessInfo().beginActivityWithOptions(.UserInitiated, reason: "FUT Trading")
        }
    }
    
    func stopTrading(reason: String, newState: State = .Stopped) {
        state = newState
        
        stopAllTimers()

        self.notifyOwner()
        
        Log.print("Trading stopped: [\(reason)].")
        
        Transaction.save(managedObjectContext)
        
        fut16.forEach { (fut) -> () in
            Log.print("Transferring [\(fut.email)]")
            fut.sendItemsToTransferList()
        }
        
        Log.print("Searches (hours): ", terminator: "")
        for i in 1...4 {
            Log.print(" \(i): \(stats.searchCountForEmail(currentFut.email, numHours: Double(i))),", terminator: "")
        }
        Log.print("")
        
        // re-enable app nap if trading stopped (as opposed to cycle break)
        if state == .Stopped && activity != nil {
            NSProcessInfo().endActivity(activity)
            activity = nil
        }
    }
    
    private func scheduleNextPoll() {
        guard state == .Ready || state == .Polling else {
            return
        }
        
        // get next valid FUT
        currentFutIdx = (currentFutIdx + 1) % fut16.count
        currentFut = fut16[currentFutIdx]
        
        pollTimer = NSTimer.scheduledTimerWithTimeInterval(settings.reqTimingRand, target: self, selector: Selector("pollAuctions"), userInfo: nil, repeats: false)
    }
    
    func cycleStart() {
        Log.print("------------------------------ Start cycle: \(settings.cycleTime) ------------------------------")
        state = .Polling
        pollAuctions()
        cycleTimer = NSTimer.scheduledTimerWithTimeInterval(settings.cycleTime, target: self, selector: Selector("cycleBreak"), userInfo: nil, repeats: false)
    }
    
    func cycleBreak() {
        Log.print("------------------------------ Break cycle: \(settings.cycleBreak) ------------------------------")
        stopTrading("Cycle break", newState: .Break)
        cycleTimer = NSTimer.scheduledTimerWithTimeInterval(settings.cycleBreak, target: self, selector: Selector("cycleStart"), userInfo: nil, repeats: false)
    }
    
    func pollAuctions() {
        Log.print("\(NSDate.localTime):  ", terminator: "")
        var curMinBin: UInt = 10000000
        
        // increment max price to avoid cached results
        itemParams.maxPrice = incrementPrice(itemParams.maxPrice)
        
        currentFut.findAuctionsForItem(itemParams) { (auctions, error) -> Void in
            defer {
                // schedule next request at the end of the callback 
                // in order to avoid sending out next request while current one is still pending
                self.scheduleNextPoll()  // set up timer for next request
            }
            
            self.stats.searchCount++
            self.logSearch()        // save to CoreData
            
            self.stats.coinsBalance = self.currentFut.coinsBalance   // grab coins ballance
            
            if self.stats.searchCountForEmail(self.currentFut.email, numHours: 1) >= self.SEARCH_LIMIT_1HR ||
               self.stats.searchCountForEmail(self.currentFut.email, numHours: 24) >= self.SEARCH_LIMIT_24HR {
                self.stopTrading("Search limit reached")
            }
            
            // check for errors
            guard error == .None else {
                Log.print(error)
                self.sessionErrorCount++
                if self.sessionErrorCount < self.SESSION_ERROR_LIMIT {
                    self.currentFut.retrieveSessionId()   // re-login
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
//                    Log.print("Purchase Queued \($0.tradeId)")
                }
            }
            
            Log.print("Search: \(self.stats.searchCount) (\(auctions.count)-\(self.itemParams.startRecord)) - Cur Min: \(curMinBin) (Min: \(self.minBin)) - \(self.itemParams.maxPrice) [\(self.currentFut.email)]")
            
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
//        Log.print("Tune: start \(itemParams.startRecord): \(auctions.first?.expiresIn) - \(auctions.last?.expiresIn)")

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
        
        Log.print("Purchasing \(auction.tradeId) (\(auction.buyNowPrice))...", terminator: "")
        self.currentFut.placeBidOnAuction(auction.tradeId, amount: auction.buyNowPrice) { (error) in
            defer {
                //NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("processPurchaseQueue"), userInfo: nil, repeats: false)
            }
            guard error == .None else {
                Log.print("Fail: Error - \(error).")
                self.stats.purchaseFailCount++
                return
            }
            
            Log.print("Success - (Bal: \(self.currentFut.coinsBalance))")
            
            // some stat keeping
            self.stats.purchaseCount++
            self.stats.lastPurchaseCost = Int(auction.buyNowPrice)
            self.stats.purchaseTotalCost += self.stats.lastPurchaseCost
            self.stats.coinsBalance = self.currentFut.coinsBalance
            self.stats.averagePurchaseCost = Int(round(Double(self.stats.purchaseTotalCost) / Double(self.stats.purchaseCount)))
            
            // add to CoreData
            Purchase.NewPurchase(self.currentFut.email, price: Int(auction.buyNowPrice), maxBin: Int(self.itemParams.maxBin), coinBallance: self.currentFut.coinsBalance, managedObjectContext: managedObjectContext)
            
            NSSound(named: "Ping")?.play()
            
            // stop trading if not enough coins for next purchase
            if self.currentFut.coinsBalance < Int(self.buyAtBin) {
                self.stopTrading("Not enough coins.  Balance: \(self.currentFut.coinsBalance)")
            }
            
            // After 5 purchases, move all to transfer list
            if self.stats.purchaseCount >= 5 {
                self.currentFut.sendItemsToTransferList()
                self.stats.purchaseCount = 0
            }
            self.notifyOwner()
        }
    }
    
    func notifyOwner() {
        self.updateOwner?()
    }
    
// MARK: Stat and CoreData helpers
    func logSearch() {
        Search.NewSearch(currentFut.email, managedObjectContext: managedObjectContext)
    }
}

public class TraderStats: NSObject {
    var searchCount = 0
    
    var purchaseCount = 0
    var purchaseFailCount = 0
    var purchaseTotalCost = 0
    
    var averagePurchaseCost = 0
    var lastPurchaseCost = 0
    var coinsBalance = 0
    
//    var searchCount1Hr: Int {
//        get {
//            return Search.numSearchesSinceDate(NSDate.hourAgo, forEmail: email, managedObjectContext: managedObjectContext)
//        }
//    }
//    var searchCount90min: Int {
//        get {
//            return Search.numSearchesSinceDate(NSDate(timeIntervalSinceNow: -60*90), forEmail: email, managedObjectContext: managedObjectContext)
//        }
//    }
//    var searchCount2Hr: Int {
//        get {
//            return Search.numSearchesSinceDate(NSDate(timeIntervalSinceNow: -2*3600), forEmail: email, managedObjectContext: managedObjectContext)
//        }
//    }
//    var searchCount24Hr: Int {
//        get {
//            return Search.numSearchesSinceDate(NSDate.dayAgo, forEmail: email, managedObjectContext: managedObjectContext)
//        }
//    }
//    
//    var searchCountAllTime: Int {
//        get {
//            return Search.numSearchesSinceDate(NSDate.allTime, forEmail: email, managedObjectContext: managedObjectContext)
//        }
//    }
//    
//    var purchaseTotalAllTime: Int {
//        get {
//            let purchases = Purchase.getPurchasesSinceDate(NSDate.allTime, forEmail: email, managedObjectContext: managedObjectContext)
//            return Int(purchases.reduce(0) { $0 + $1.price })
//        }
//    }
    
    func searchCountForEmail(email: String, numHours hours: Double) -> Int {
        return Search.numSearchesSinceDate(NSDate(timeIntervalSinceNow: -3600*hours), forEmail: email, managedObjectContext: managedObjectContext)
    }
}