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
        
        if let stats = getStatsForEmail(email, managedObjectContext: managedObjectContext) {
            print("Stats for email \(stats.email) - \(stats.numSearches)")
            stats.email = email
            stats.numSearches = searchCount

        } else {
            print("Creating new stat")
            let stat = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext) as! Stats
            stat.email = email
            stat.numSearches = searchCount
        }
        
        //save(managedObjectContext)
    }
    
    class func getSearchCountForEmail(email: String, managedObjectContext: NSManagedObjectContext) -> Int {
        var searchCount = 0
        
        if let stats = getStatsForEmail(email, managedObjectContext: managedObjectContext) {
            searchCount = Int(stats.numSearches)
        }
        
        return searchCount
    }
    
    private class func getStatsForEmail(email: String, managedObjectContext: NSManagedObjectContext) -> Stats? {
        
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "email = %@", email)
        
        do {
            let stats = try managedObjectContext.executeFetchRequest(fetchRequest) as! [Stats]
            print("Stats count: \(stats.count)")
            return stats.first
        } catch {
            fatalError("Failed \(entityName) fetch!")
        }
        
    }

    
    class func save(managedObjectContext: NSManagedObjectContext) {
        do {
            try managedObjectContext.save()
        } catch {
            Log.print("Failed to save managed object context")
        }
    }
}
