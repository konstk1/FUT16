//
//  Transaction.swift
//  FUT16
//
//  Created by Kon on 1/2/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation
import CoreData


class Transaction: NSManagedObject {
    
    class func getTransactions(_ entityName: String, forEmail email: String, sinceDate date: Date, managedObjectContext: NSManagedObjectContext) -> [Transaction] {
        
        let sortByTime = NSSortDescriptor(key: "time", ascending: true)
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "email = %@ AND time >= %@", email, date as NSDate)
        fetchRequest.sortDescriptors = [sortByTime]
        
        do {
            let transactions = try managedObjectContext.fetch(fetchRequest) as! [Transaction]
            return transactions
        } catch {
            fatalError("Failed \(entityName) fetch!")
        }
    }
    
    class func getTransactions(_ entityName: String, forEmail email: String, beforeDate date: Date, managedObjectContext: NSManagedObjectContext) -> [Transaction] {
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        
        fetchRequest.predicate = NSPredicate(format: "email = %@ AND time < %@", email, date as NSDate)
        
        do {
            let transactions = try managedObjectContext.fetch(fetchRequest) as! [Transaction]
            return transactions
        } catch {
            fatalError("Failed \(entityName) fetch!")
        }
    }
    
    class func numTransactions(_ entityName: String, forEmail email: String, sinceDate date: Date, managedObjectContext: NSManagedObjectContext) -> Int {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        fetchRequest.includesPropertyValues = false
        fetchRequest.includesSubentities = false
        fetchRequest.resultType = NSFetchRequestResultType.countResultType
        
        fetchRequest.predicate = NSPredicate(format: "email = %@ AND time >= %@", email, date as NSDate)
        
        return try! managedObjectContext.count(for: fetchRequest)
    }

    class func save(_ managedObjectContext: NSManagedObjectContext) {
        do {
            try managedObjectContext.save()
        } catch {
            Log.print("Failed to save managed object context")
        }
    }
    
}
