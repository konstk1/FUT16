//
//  Stats.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 3/13/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation
import CoreData


class Stats: NSManagedObject {
    static let entityName = "Stats"
    
    class func updateSearchCount(email: String, searchCount: Int32, managedObjectContext: NSManagedObjectContext) {
        
        let fetchRequest = NSFetchRequest(entityName: entityName)
        
        fetchRequest.predicate = NSPredicate(format: "email = %@", email)
        
        do {
            let stats = try managedObjectContext.executeFetchRequest(fetchRequest) as! [Stats]
            print("Stats count: \(stats.count)")
            if stats.isEmpty {
                print("Creating new stat")
                let stat = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext) as! Stats
                stat.email = email
                stat.numSearches = searchCount
            }
            if let stat = stats.first {
                print("Stats for email \(stat.email) - \(stat.numSearches)")
                stat.email = email
                stat.numSearches = searchCount
            }
        } catch {
            fatalError("Failed \(entityName) fetch!")
        }
        
        //save(managedObjectContext)
    }
    
    class func save(managedObjectContext: NSManagedObjectContext) {
        do {
            try managedObjectContext.save()
        } catch {
            Log.print("Failed to save managed object context")
        }
    }
}
