//
//  Purchase+CoreDataProperties.swift
//  FUT16
//
//  Created by Kon on 1/8/16.
//  Copyright © 2016 Kon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Purchase {

    @NSManaged var coinBalance: Int32
    @NSManaged var maxBin: Int32
    @NSManaged var price: Int32

}
