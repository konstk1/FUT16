//
//  Purchase.swift
//  FUT16
//
//  Created by Kon on 1/2/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation
import CoreData


class Purchase: Transaction {

    static let entityName = "Purchase"
    
    override var description: String {
        get {
            return "Purchase price: \(price) BIN: \(maxBin) CoinsPre: \(coinBalance + price) Time: \(Int(round(time)))"
        }
    }
    
    class func NewPurchase(_ email: String, price: Int, maxBin: Int, coinBallance: Int, managedObjectContext: NSManagedObjectContext) {
        let purchase = NSEntityDescription.insertNewObject(forEntityName: entityName, into: managedObjectContext) as! Purchase
        
        purchase.email = email
        purchase.time = Date().timeIntervalSinceReferenceDate
        purchase.price = Int32(price)
        purchase.maxBin = Int32(maxBin)
        purchase.coinBalance = Int32(coinBallance)
        
//        save(managedObjectContext)
    }
    
    class func getPurchasesSinceDate(_ date: Date, forEmail email: String, managedObjectContext: NSManagedObjectContext) -> [Purchase] {
        let purchases = getTransactions(entityName, forEmail: email, sinceDate: date, managedObjectContext: managedObjectContext) as! [Purchase]
        return purchases.sorted { $0.time < $1.time }
    }
    
}
