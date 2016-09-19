//
//  Utilities.swift
//  FUT16
//
//  Created by Kon on 12/20/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation

public enum FutError: Error {
    case none
    case expiredSession
    case internalServerError    // 500
    case purchaseFailed
    case bidNotAllowed
    case notEnoughCredit        // 470
}

func incrementPrice(_ price: UInt) -> UInt {
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

func decrementPrice(_ price: UInt) -> UInt {
    var decr: UInt = 0
    
    guard price >= 50 else {
        return 0
    }

    if price <= 1000 {
        decr = 50
    } else if price <= 10000 {
        decr = 100
    } else if price <= 50000 {
        decr = 250
    } else if price <= 100000 {
        decr = 500
    } else {
        decr = 1000
    }
    
    return price - decr
}

extension Date {
    static var hourAgo: Date {
        get {
            return Date(timeIntervalSinceNow: -3600)
        }
    }
    
    static var dayAgo: Date {
        get {
            return Date(timeIntervalSinceNow: -24 * 3600)
        }
    }
    
    static var twoDaysAgo: Date {
        get {
            return Date(timeIntervalSinceNow: -48 * 3600)
        }
    }
    
    static var allTime: Date {
        get {
            return Date(timeIntervalSinceReferenceDate: 0)
        }
    }
    
    static func hoursAgo(_ hours: Double) -> Date {
        return Date(timeIntervalSinceNow: -3600 * hours)
    }
    
    var localTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter.string(from: self)
    }
}
