//
//  Utilities.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 12/20/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation

public enum FutError: ErrorType {
    case None
    case ExpiredSession
    case InternalServerError    // 500
    case PurchaseFailed
    case BidNotAllowed
}

func incrementPrice(price: UInt) -> UInt {
    var incr: UInt
    
    if price < 1000 {
        incr = 50
    } else if price < 10000 {
        incr = 100
    } else if price < 50000 {
        incr = 250
    } else if price < 100000 {
        incr = 500
    } else {
        incr = 1000
    }
    
    return price + incr
}

extension NSDate {
    static var hourAgo: NSDate {
        get {
            return NSDate(timeIntervalSinceNow: -3600)
        }
    }
    
    static var dayAgo: NSDate {
        get {
            return NSDate(timeIntervalSinceNow: -24 * 3600)
        }
    }
}