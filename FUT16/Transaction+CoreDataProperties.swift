//
//  Transaction+CoreDataProperties.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 2/22/16.
//  Copyright © 2016 Kon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Transaction {

    @NSManaged var time: NSTimeInterval
    @NSManaged var email: String?

}
