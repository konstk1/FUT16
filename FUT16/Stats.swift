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
        
    class func updateSearchCount(_ email: String, searchCount: Int32, managedObjectContext: NSManagedObjectContext) {
        var stats = getStatsForEmail(email, managedObjectContext: managedObjectContext)
        
        if stats == nil {
            stats = NSEntityDescription.insertNewObject(forEntityName: entityName, into: managedObjectContext) as? Stats
        }
        
        stats?.email = email
        stats?.numSearches = searchCount
        
        //save(managedObjectContext)
    }
    
    class func getSearchCountForEmail(_ email: String, managedObjectContext: NSManagedObjectContext) -> Int {
        var searchCount = 0
        
        if let stats = getStatsForEmail(email, managedObjectContext: managedObjectContext) {
            searchCount = Int(stats.numSearches)
        }
        
        return searchCount
    }
    
    fileprivate class func getStatsForEmail(_ email: String, managedObjectContext: NSManagedObjectContext) -> Stats? {
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "email = %@", email)
        
        do {
            let stats = try managedObjectContext.fetch(fetchRequest) as! [Stats]
            return stats.first
        } catch {
            fatalError("Failed \(entityName) fetch!")
        }
        
    }

    
    class func save(_ managedObjectContext: NSManagedObjectContext) {
        do {
            try managedObjectContext.save()
        } catch {
            Log.print("Failed to save managed object context")
        }
    }
}
