//
//  UserStats.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 3/9/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation
import Cocoa

private let managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

class UserStats: NSObject {
    var email: String {
        didSet {
            reset()
        }
    }
    dynamic var coinsBalance = 0
    
    init(email: String) {
        self.email = email
    }
    
    dynamic var searchCount = 0
    dynamic var searchCount1Hr = 0
    dynamic var searchCount2Hr = 0
    dynamic var searchCount24Hr = 0
    dynamic var searchCountAllTime = 0
    
    dynamic var purchaseCount = 0
    dynamic var purchaseFailCount = 0 {
        didSet {
            AggregateStats.sharedInstance.purchaseFailCount += (purchaseFailCount - oldValue)
        }
    }
    dynamic var purchaseTotalCost = 0
    dynamic var averagePurchaseCost = 0
    dynamic var lastPurchaseCost = 0
    dynamic var purchaseTotalAllTime = 0
    
    var unassignedItems = 0
    
    var errorCount = 0
    
    private let managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    func searchCountHours(hours: Double) -> Int {
        return Search.numSearchesSinceDate(NSDate(timeIntervalSinceNow: -3600*hours), forEmail: email, managedObjectContext: managedObjectContext)
    }
    
    func logSearch() {
        Search.NewSearch(email, managedObjectContext: managedObjectContext)
        Stats.updateSearchCount(email, searchCount: searchCountAllTime+1, managedObjectContext: managedObjectContext)
        // this should be done after search is logged so that didSet updates various counters with new search
        searchCount += 1
        AggregateStats.sharedInstance.searchCount += 1
        
        searchCount1Hr = Search.numSearchesSinceDate(NSDate.hourAgo, forEmail: email, managedObjectContext: managedObjectContext)
        //searchCount2Hr = Search.numSearchesSinceDate(NSDate(timeIntervalSinceNow: -2*3600), forEmail: email, managedObjectContext: managedObjectContext)
        searchCount24Hr = Search.numSearchesSinceDate(NSDate.dayAgo, forEmail: email, managedObjectContext: managedObjectContext)
        searchCountAllTime = Stats.getSearchCountForEmail(email, managedObjectContext: managedObjectContext)
    }
    
    func logPurchase(purchaseCost: Int, maxBin: Int, coinsBalance: Int) {
        // add to CoreData
        Purchase.NewPurchase(email, price: purchaseCost, maxBin: maxBin, coinBallance: coinsBalance, managedObjectContext: managedObjectContext)
        
        // this should be done after purchase is logged so that didSet updates various counters with new purchase
        lastPurchaseCost = purchaseCost
        self.coinsBalance = coinsBalance
        unassignedItems += 1
        
        purchaseCount += 1
        purchaseTotalCost += lastPurchaseCost
        averagePurchaseCost = Int(round(Double(purchaseTotalCost) / Double(purchaseCount)))
        let purchases = Purchase.getPurchasesSinceDate(NSDate.allTime, forEmail: email, managedObjectContext: managedObjectContext)
        purchaseTotalAllTime = Int(purchases.reduce(0) { $0 + $1.price })
        
        AggregateStats.sharedInstance.purchaseCount += 1
        AggregateStats.sharedInstance.lastPurchaseCost = lastPurchaseCost
        
    }
    
    func reset() {
        searchCount = 0
        purchaseCount = 0
        purchaseFailCount = 0
        purchaseTotalCost = 0
        lastPurchaseCost = 0
        averagePurchaseCost = 0
    }
    
    func purgeOldSearches() {
        Search.purgeSearchesOlderThan(NSDate.hoursAgo(26), forEmail: email, managedObjectContext: managedObjectContext)
    }
    
    func save() {
        Transaction.save(managedObjectContext)
        Stats.save(managedObjectContext)
    }
}

class AggregateStats: NSObject {
    static var sharedInstance = AggregateStats()
    
    dynamic var searchCount = 0
    dynamic var purchaseCount = 0
    dynamic var purchaseFailCount = 0
    dynamic var purchaseTotalCost = 0
    dynamic var lastPurchaseCost = 0 {
        didSet {
            purchaseTotalCost += lastPurchaseCost
            averagePurchaseCost = (purchaseCount == 0) ? 0 : Int(round(Double(purchaseTotalCost) / Double(purchaseCount)))
        }
    }
    dynamic var averagePurchaseCost = 0
    
    func reset() {
        searchCount = 0
        purchaseCount = 0
        purchaseFailCount = 0
        purchaseTotalCost = 0
        lastPurchaseCost = 0
    }
}