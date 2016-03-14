//
//  Stats+CoreDataProperties.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 3/13/16.
//  Copyright © 2016 Kon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Stats {

    @NSManaged var email: String
    @NSManaged var numSearches: Int32

}
