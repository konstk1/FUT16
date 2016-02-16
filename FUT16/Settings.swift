//
//  Settings.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 2/16/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation

class Settings: CustomStringConvertible {
    static var sharedInstance = Settings()
    
    var reqTimingMin: NSTimeInterval = 2.0
    var reqTimingMax: NSTimeInterval = 3.0
    
    var reqTimingRand: NSTimeInterval {
        return (Double(arc4random()) / Double(UINT32_MAX)) * (reqTimingMax - reqTimingMin) + reqTimingMin
    }
    
    var cycleTime: NSTimeInterval    = 30
    var cycleBreak: NSTimeInterval   = 15
    
    var unlockCode: String = ""
    
    var description: String {
        return "Req timing \(reqTimingMin)-\(reqTimingMax) sec, cycle \(cycleTime/60) / \(cycleBreak/60)"
    }
}