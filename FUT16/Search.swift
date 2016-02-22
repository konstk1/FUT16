//
//  Search.swift
//  FUT16
//
//  Created by Kon on 1/2/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation
import CoreData


class Search: Transaction {
    static let entityName = "Search"
    
    override var description: String { get { return "\(NSDate(timeIntervalSinceReferenceDate: time))" } }
    
    class func NewSearch(email: String, managedObjectContext managedObjectContext: NSManagedObjectContext) {
        let search = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext) as! Search
        search.email = email
        search.time = NSDate().timeIntervalSinceReferenceDate
        
//        save(managedObjectContext)
    }
    
    // if hours is nil, fetch all
    class func getSearchesSinceDate(date: NSDate, forEmail email: String, managedObjectContext: NSManagedObjectContext) -> [Search] {
        
        return getTransactions(entityName, forEmail: email, sinceDate: date, managedObjectContext: managedObjectContext) as! [Search]
    }
    
    class func numSearchesSinceDate(date: NSDate, forEmail email: String, managedObjectContext: NSManagedObjectContext) -> Int {
        return numTransactions(entityName, forEmail: email, sinceDate: date, managedObjectContext: managedObjectContext)
    }
}
