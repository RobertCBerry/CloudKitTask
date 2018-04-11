//
//  RecordConfiguration.swift
//  CloudKitTask
//
//  Created by Robert Berry on 4/10/18.
//  Copyright © 2018 Robert Berry. All rights reserved.
//

import Foundation
import CloudKit

// Creates typealias' for cloud kit record objects. 

typealias Restaurant = CKRecord
typealias MenuItem = CKRecord

// Struct holds recordType and name for a resturant CKRecord. 

struct RestaurantProperties {
   
    static let recordType = "Restaurants"
    
    static let name = "name"

}

// Struct holds recordType, name, and restaurant for a menu item CKRecord.

struct MenuItemProperties {
   
    static let recordType = "MenuItems"
    
    static let name = "name"
   
    static let restaurant = "restaurant"

}
