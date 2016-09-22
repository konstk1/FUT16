//
//  AutoTrader.swift
//  FUT16
//
//  Created by Kon on 12/21/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import Cocoa
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


open class AutoTrader: NSObject {
    fileprivate var users = [FutUser]()
    fileprivate var currentUser: FutUser
    fileprivate var currentUserIdx = 0
    
    fileprivate var itemParams: FUT16.ItemParams!
    fileprivate var buyAtBin: UInt = 0
    
    fileprivate let SESSION_ERROR_LIMIT = 3      // stop trading after this many session errors
    fileprivate let SEARCH_LIMIT_1HR = 950       // stop trading after this many searches within 1 hour
    fileprivate let SEARCH_LIMIT_24HR = 4000     // stop trading after this many searches within 24 hours
    
    fileprivate var pollTimer: Timer!
    fileprivate var cycleTimer: Timer!
    
    dynamic var requestPeriod: TimeInterval = 0.0 {
        didSet {
            let settings = Settings.sharedInstance
            requestRate = Int(3600 * settings.cycleTime/(settings.cycleTime + settings.cycleBreak) / requestPeriod)
        }
    }
    dynamic var requestRate: Int = 0
    
    enum State {
        case ready
        case polling
        case `break`
        case stopped
    }
    
    fileprivate var state = State.ready
    
    fileprivate(set) open var minBin: UInt = 10000000
    
    fileprivate var purchaseQueue = Array<FUT16.AuctionInfo>()
    
    fileprivate var settings = Settings.sharedInstance
    
    fileprivate var updateOwner: ((_ user: FutUser) -> ())?
    
    fileprivate var activity: NSObjectProtocol!      // activity to disable app nap
    
    public init(users: [FutUser], update: ((_ user: FutUser) -> ())?) {
        self.users = users
        currentUser = self.users.first!
        
        self.updateOwner = update
    }
    
    // return break-even buy
    func setTradeParams(_ itemParams: FUT16.ItemParams, buyAtBin: UInt) -> UInt {
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
    
    func resetStats(_ user: FutUser?) {
        // if user is nil, reset all
        if user == nil {
            users.forEach { (user) -> () in
                user.resetStats()
            }
        } else {
            user?.resetStats()
        }
        
        AggregateStats.sharedInstance.reset()
        
        minBin = 10000000
        
        notifyOwner(self.currentUser)
    }
    
    func stopAllTimers() {
        if pollTimer != nil && pollTimer.isValid {
            pollTimer.invalidate()
        }
        
        if cycleTimer != nil && cycleTimer.isValid {
            cycleTimer.invalidate()
        }
    }
    
    func startTrading() {
        Log.print("State: \(state)")
        
        guard numActiveUsers > 0 else {
            Log.print("No active users")
            return
        }
        
        if state == .ready || state == .stopped {
            cycleStart()
        } else {
            Log.print("Already trading")
        }
        
        // disable app nap
        if activity == nil {
            activity = ProcessInfo().beginActivity(options: .userInitiated, reason: "FUT Trading")
        }
    }
    
    func stopTrading(_ reason: String, newState: State = .stopped) {
        state = newState
        
        stopAllTimers()

        self.notifyOwner(currentUser)
        
        Log.print("Trading stopped: [\(reason)].")
        
        users.forEach { user in
            user.stats.purgeOldSearches()
            if user.stats.purchaseCount > 0 {
                user.fut16.sendItemsToTransferList()
            }
        }
        
        // saves data for all users (core data context)
        currentUser.stats.save()
        
        Log.print("Searches (hours): ", terminator: "")
        for i in [1, 2, 12, 24] {
            Log.print(" \(i): \(users.first!.stats.searchCountHours(Double(i))),", terminator: "")
        }
        Log.print("")
        
        // re-enable app nap if trading stopped (as opposed to cycle break)
        if state == .stopped && activity != nil {
            ProcessInfo().endActivity(activity)
            activity = nil
        }
    }
    
    fileprivate var lastRequestTime = Date().timeIntervalSinceReferenceDate
    
    fileprivate func scheduleNextPoll() {
        guard state == .ready || state == .polling else {
            return
        }
        
        let prevUserIdx = currentUserIdx
        
        // get next valid FUT
        repeat {
            currentUserIdx = (currentUserIdx + 1) % users.count
            currentUser = users[currentUserIdx]
        } while !currentUser.ready
        
        // wrapped arround
        if prevUserIdx >= currentUserIdx {
            let curRequestTime = Date().timeIntervalSinceReferenceDate
            requestPeriod = round((curRequestTime - lastRequestTime)*10)/10
//            Log.print("Account request period: \(requestPeriod) secs  (Users: \(numActiveUsers))")
            lastRequestTime = curRequestTime
        }
        
        let nextPollTiming = settings.reqTimingRand / Double(numActiveUsers)
        
        pollTimer = Timer.scheduledTimer(timeInterval: nextPollTiming, target: self, selector: #selector(AutoTrader.pollAuctions), userInfo: currentUser, repeats: false)
    }
    
    func cycleStart() {
        Log.print("------------------------------ Start cycle: \(settings.cycleTime) ------------------------------")
        state = .polling
        scheduleNextPoll()
        cycleTimer = Timer.scheduledTimer(timeInterval: settings.cycleTime, target: self, selector: #selector(AutoTrader.cycleBreak), userInfo: nil, repeats: false)
        
        let start = Date()
        let end = start.addingTimeInterval(settings.cycleTime)
        AggregateStats.sharedInstance.cycleStart = start.localTime + " - " + end.localTime
    }
    
    func cycleBreak() {
        Log.print("------------------------------ Break cycle: \(settings.cycleBreak) ------------------------------")
        stopTrading("Cycle break", newState: .break)
        cycleTimer = Timer.scheduledTimer(timeInterval: settings.cycleBreak, target: self, selector: #selector(AutoTrader.cycleStart), userInfo: nil, repeats: false)
        
        let start = Date()
        let end = start.addingTimeInterval(settings.cycleBreak)
        AggregateStats.sharedInstance.cycleStart = start.localTime + " - " + end.localTime
    }
    
    func pollAuctions() {
        guard let user = pollTimer.userInfo as? FutUser else {
            Log.print("Invalid user")
            return
        }

        var curMinBin: UInt = 10000000
        
        // increment max price to avoid cached results
        itemParams.maxPrice = incrementPrice(itemParams.maxPrice)
        
        user.fut16.findAuctionsForItem(itemParams) { [unowned self] (auctions, error) -> Void in
            let currentStats = user.stats
            let currentFut = user.fut16
            
            currentStats.coinsBalance = currentFut.coinsBalance   // grab coins ballance
            
            if currentStats.searchCount1Hr >= self.SEARCH_LIMIT_1HR ||
               currentStats.searchCount24Hr >= self.SEARCH_LIMIT_24HR {
                self.stopTrading("Search limit reached")
            }
            
            // check for errors
            guard error == .none else {
                Log.print(error)
                if error == .expiredSession {
                    Log.print("Retrieving session id")
                    currentFut.retrieveSessionId()   // re-login
                } else {
                    currentStats.errorCount += 1
                    self.stopTrading("Session error limit reached")
                }
                return
            }
            
            // find current search min bins
            auctions.forEach {
                if let playerParams = self.itemParams as? FUT16.PlayerParams, let teamId = UInt(playerParams.team) {
                    if teamId != $0.teamId {
                        print("Wrong team Id (\(teamId) vs \($0.teamId))")
                        return
                    }
                }
                
                if $0.buyNowPrice < curMinBin {
                    curMinBin = $0.buyNowPrice
                }
                
                if $0.buyNowPrice <= self.buyAtBin { //&& $0.isRare {
                    self.purchaseQueue.append($0)
//                    Log.print("Purchase Queued \($0.tradeId)")
                }
            }
            
            // update session min
            if curMinBin < self.minBin {
                self.minBin = curMinBin
            }
            
            self.processPurchaseQueue(user)
            self.tuneSearchParamsFromAuctions(auctions)
            
            // log search at the end to minimize time between search and purchase
            currentStats.logSearch()        // save to CoreData
            Log.print("\(Date().localTime):  Search: \(currentStats.searchCount) (\(auctions.count)-\(self.itemParams.startRecord)) - Cur Min: \(curMinBin) (Min: \(self.minBin)) [\(currentFut.user)]")
            
            self.notifyOwner(user)
        } // findAuctionsForPlayer
        
        scheduleNextPoll()  // set up timer for next request
        
    } // end pollAuctions
    
    func tuneSearchParamsFromAuctions(_ auctions: [FUT16.AuctionInfo]) {
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
    
    func processPurchaseQueue(_ user: FutUser) {
        guard purchaseQueue.count > 0 else { return }
        
        let currentFut = user.fut16
        
        let auction = purchaseQueue.removeFirst()
        
        Log.print("Purchasing \(auction.tradeId) (\(auction.buyNowPrice))...", terminator: "")
        currentFut.placeBidOnAuction(auction.tradeId, amount: auction.buyNowPrice) { [unowned self] (email, error) in
            defer {
                //NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("processPurchaseQueue"), userInfo: nil, repeats: false)
            }
            
            let user = self.findUserWithEmail(email)!
            
            guard error == .none else {
                Log.print("Fail: Error - \(error).")
                user.stats.purchaseFailCount += 1
                return
            }
            
            Log.print("Success - (Bal: \(currentFut.coinsBalance))")
            
            // some stat keeping
            user.stats.logPurchase(Int(auction.buyNowPrice), maxBin: Int(self.itemParams.maxBin), coinsBalance: user.fut16.coinsBalance)
            
            NSSound(named: "Ping")?.play()
            
            // stop trading if not enough coins for next purchase
            if user.stats.coinsBalance < Int(self.buyAtBin) {
                self.stopTrading("Not enough coins.  Balance: \(user.stats.coinsBalance)")
            }
            
            // After 5 purchases, move all to transfer list
            if user.stats.unassignedItems >= 5 {
                user.fut16.sendItemsToTransferList()
                user.stats.unassignedItems = 0
            }
            self.notifyOwner(user)
        }
    }
    
    func findUserWithEmail(_ email: String) -> FutUser! {
        for user in users {
            if user.email == email {
                return user
            }
        }
        
        return nil
    }
    
    func notifyOwner(_ user: FutUser) {
        self.updateOwner?(user)
    }
    
    var numActiveUsers: Int {
        return users.reduce(0) { (count, user) in
            return user.ready ? count + 1 : count
        }
    }
}
