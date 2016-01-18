//
//  Search.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 1/2/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation
import CoreData


class Search: Transaction {
    static let entityName = "Search"
    
    override var description: String { get { return "\(NSDate(timeIntervalSinceReferenceDate: time))" } }
    
    class func NewSearch(managedObjectContext managedObjectContext: NSManagedObjectContext) {
        let search = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext) as! Search
        search.time = NSDate().timeIntervalSinceReferenceDate
        
        save(managedObjectContext)
    }
    
    // if hours is nil, fetch all
    class func getSearchesSinceDate(date: NSDate, managedObjectContext: NSManagedObjectContext) -> [Search] {
        
        return getTransactions(entityName, sinceDate: date, managedObjectContext: managedObjectContext) as! [Search]
    }
    
    class func numSearchesSinceDate(date: NSDate, managedObjectContext: NSManagedObjectContext) -> Int {
        return numTransactions(entityName, sinceDate: date, managedObjectContext: managedObjectContext)
    }
}
