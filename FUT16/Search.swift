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
    
// Insert code here to add functionality to your managed object subclass
    class func NewSearch(managedObjectContext managedObjectContext: NSManagedObjectContext) {
        let search = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: managedObjectContext) as! Search
        search.time = NSDate().timeIntervalSinceReferenceDate
        try! managedObjectContext.save()
    }
    
    // if hours is nil, fetch all
    class func getSearchesSinceDate(date: NSDate, managedObjectContext: NSManagedObjectContext) -> [Search] {
        
        let fetchRequest = NSFetchRequest(entityName: "Search")
        
        fetchRequest.predicate = NSPredicate(format: "time >= %@", date)
        
        do {
            let searches = try managedObjectContext.executeFetchRequest(fetchRequest) as! [Search]
            return searches
        } catch {
            fatalError("Failed search fetch!")
        }
    }


}
