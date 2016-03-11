//
//  AutoTrader.swift
//  FUT16
//
//  Created by Kon on 12/21/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import Cocoa

// TODO: Re-login on expired session
// TODO: Autoprice?

public class AutoTrader: NSObject {
    private var users = [FutUser]()
    private var currentUser: FutUser
    private var currentUserIdx = 0
    
    private var currentStats: TraderStats { return currentUser.stats }
    private var currentFut: FUT16 { return currentUser.fut16 }
    
    private var itemParams: FUT16.ItemParams!
    private var buyAtBin: UInt = 0
    
    private let SESSION_ERROR_LIMIT = 3      // stop trading after this many session errors
    private let SEARCH_LIMIT_1HR = 950       // stop trading after this many searches within 1 hour
    private let SEARCH_LIMIT_24HR = 5000     // stop trading after this many searches within 24 hours
    
    private var pollTimer: NSTimer!
    private var cycleTimer: NSTimer!
    
    private let managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    enum State {
        case Ready
        case Polling
        case Break
        case Stopped
    }
    
    private var state = State.Ready
    
    private(set) public var minBin: UInt = 10000000
    
    private var purchaseQueue = Array<FUT16.AuctionInfo>()
    
    private var settings = Settings.sharedInstance
    
    private var updateOwner: ((user: FutUser) -> ())?
    
    private var activity: NSObjectProtocol!      // activity to disable app nap
    
    public init(users: [FutUser], update: ((user: FutUser) -> ())?) {
        self.users = users
        currentUser = self.users.first!
        
        self.updateOwner = update
        
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
        users.forEach { (user) -> () in
            user.resetStats()
        }
        
        minBin = 10000000
        notifyOwner(self.currentUser)
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
        
        guard numActiveUsers > 0 else {
            Log.print("No active users")
            return
        }
        
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

        self.notifyOwner(self.currentUser)
        
        Log.print("Trading stopped: [\(reason)].")
        
        Transaction.save(managedObjectContext)
        
        users.forEach { (user) -> () in
            user.fut16.sendItemsToTransferList()
        }
        
        Log.print("Searches (hours): ", terminator: "")
        for i in [1, 2, 12, 24] {
            Log.print(" \(i): \(users.first!.stats.searchCountHours(Double(i))),", terminator: "")
        }
        Log.print("")
        
        // re-enable app nap if trading stopped (as opposed to cycle break)
        if state == .Stopped && activity != nil {
            NSProcessInfo().endActivity(activity)
            activity = nil
        }
    }
    
    private var lastRequestTime = NSDate().timeIntervalSinceReferenceDate
    
    private func scheduleNextPoll() {
        guard state == .Ready || state == .Polling else {
            return
        }
        
        if currentUserIdx == 0 {
            let curRequestTime = NSDate().timeIntervalSinceReferenceDate
            users[currentUserIdx].requestPeriod = round((curRequestTime - lastRequestTime)*10)/10
            Log.print("Account request period: \(users[currentUserIdx].requestPeriod) secs  (Users: \(numActiveUsers))")
            lastRequestTime = curRequestTime
        }
        
        // get next valid FUT
        repeat {
            currentUserIdx = (currentUserIdx + 1) % users.count
            currentUser = users[currentUserIdx]
        } while !currentUser.ready
        
        let nextPollTiming = settings.reqTimingRand / Double(numActiveUsers)
        
        pollTimer = NSTimer.scheduledTimerWithTimeInterval(nextPollTiming, target: self, selector: Selector("pollAuctions"), userInfo: nil, repeats: false)
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
        
        currentUser.fut16.findAuctionsForItem(itemParams) { (auctions, error) -> Void in
            defer {
                // schedule next request at the end of the callback 
                // in order to avoid sending out next request while current one is still pending
                self.scheduleNextPoll()  // set up timer for next request
            }
            
            self.currentStats.searchCount++
            self.logSearch()        // save to CoreData
            
            self.currentStats.coinsBalance = self.currentFut.coinsBalance   // grab coins ballance
            
            if self.currentStats.searchCount1Hr >= self.SEARCH_LIMIT_1HR ||
               self.currentStats.searchCount24Hr >= self.SEARCH_LIMIT_24HR {
                self.stopTrading("Search limit reached")
            }
            
            // check for errors
            guard error == .None else {
                Log.print(error)
                if error == .ExpiredSession {
                    Log.print("Retrieving session id")
                    self.currentFut.retrieveSessionId()   // re-login
                } else {
                    self.currentStats.errorCount++
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
            
            Log.print("Search: \(self.currentStats.searchCount) (\(auctions.count)-\(self.itemParams.startRecord)) - Cur Min: \(curMinBin) (Min: \(self.minBin)) [\(self.currentFut.user)]")
            
            // update session min
            if curMinBin < self.minBin {
                self.minBin = curMinBin
            }
            
            self.processPurchaseQueue()
            self.tuneSearchParamsFromAuctions(auctions)
            
            self.notifyOwner(self.currentUser)
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
        self.currentFut.placeBidOnAuction(auction.tradeId, amount: auction.buyNowPrice) { [unowned self] (email, error) in
            defer {
                //NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("processPurchaseQueue"), userInfo: nil, repeats: false)
            }
            
            let user = self.findUserWithEmail(email)
            
            guard error == .None else {
                Log.print("Fail: Error - \(error).")
                user.stats.purchaseFailCount++
                return
            }
            
            Log.print("Success - (Bal: \(self.currentFut.coinsBalance))")
            
            // some stat keeping
            user.stats.purchaseCount++
            user.stats.lastPurchaseCost = Int(auction.buyNowPrice)
            user.stats.coinsBalance = user.fut16.coinsBalance
            
            // add to CoreData
            Purchase.NewPurchase(user.email, price: Int(auction.buyNowPrice), maxBin: Int(self.itemParams.maxBin), coinBallance: user.stats.coinsBalance, managedObjectContext: self.managedObjectContext)
            
            NSSound(named: "Ping")?.play()
            
            // stop trading if not enough coins for next purchase
            if user.stats.coinsBalance < Int(self.buyAtBin) {
                self.stopTrading("Not enough coins.  Balance: \(user.stats.coinsBalance)")
            }
            
            // After 5 purchases, move all to transfer list
            if user.stats.purchaseCount >= 5 {
                user.fut16.sendItemsToTransferList()
                user.stats.purchaseCount = 0
            }
            self.notifyOwner(user)
        }
    }
    
    func findUserWithEmail(email: String) -> FutUser! {
        for user in users {
            if user.email == email {
                return user
            }
        }
        
        return nil
    }
    
    func notifyOwner(user: FutUser) {
        self.updateOwner?(user: user)
    }
    
    var numActiveUsers: Int {
        return users.reduce(0) { (count, user) in
            return user.ready ? count + 1 : count
        }
    }
    
// MARK: Stat and CoreData helpers
    func logSearch() {
        Search.NewSearch(currentFut.email, managedObjectContext: managedObjectContext)
    }
}