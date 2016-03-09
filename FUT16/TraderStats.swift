//
//  TraderStats.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 3/9/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation
import Cocoa

public class TraderStats: NSObject {
    var email: String
    
    init(email: String) {
        self.email = email
    }
    
    var searchCount = 0
    
    var purchaseCount = 0
    var purchaseFailCount = 0
    var purchaseTotalCost = 0
    
    var averagePurchaseCost: Int { return purchaseCount == 0 ? 0 : Int(round(Double(purchaseTotalCost) / Double(purchaseCount))) }
    
    var lastPurchaseCost = 0 {
        didSet {
            purchaseTotalCost += lastPurchaseCost
        }
    }
    
    var coinsBalance = 0
    
    var errorCount = 0
    
    private let managedObjectContext = (NSApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    var searchCount1Hr: Int {
        get {
            return Search.numSearchesSinceDate(NSDate.hourAgo, forEmail: email, managedObjectContext: managedObjectContext)
        }
    }
    var searchCount90min: Int {
        get {
            return Search.numSearchesSinceDate(NSDate(timeIntervalSinceNow: -60*90), forEmail: email, managedObjectContext: managedObjectContext)
        }
    }
    var searchCount2Hr: Int {
        get {
            return Search.numSearchesSinceDate(NSDate(timeIntervalSinceNow: -2*3600), forEmail: email, managedObjectContext: managedObjectContext)
        }
    }
    var searchCount24Hr: Int {
        get {
            return Search.numSearchesSinceDate(NSDate.dayAgo, forEmail: email, managedObjectContext: managedObjectContext)
        }
    }
    
    var searchCountAllTime: Int {
        get {
            return Search.numSearchesSinceDate(NSDate.allTime, forEmail: email, managedObjectContext: managedObjectContext)
        }
    }
    
    var purchaseTotalAllTime: Int {
        get {
            let purchases = Purchase.getPurchasesSinceDate(NSDate.allTime, forEmail: email, managedObjectContext: managedObjectContext)
            return Int(purchases.reduce(0) { $0 + $1.price })
        }
    }
    
    func searchCountHours(hours: Double) -> Int {
        return Search.numSearchesSinceDate(NSDate(timeIntervalSinceNow: -3600*hours), forEmail: email, managedObjectContext: managedObjectContext)
    }
}