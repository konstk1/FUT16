//
//  FutUser.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 3/9/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation

public class FutUser: NSObject {
    let fut16 = FUT16()
    
    lazy var stats: UserStats = { [unowned self] in return UserStats(email: self.email) }()
    dynamic var requestPeriod: NSTimeInterval = 0.0 {
        didSet {
            let settings = Settings.sharedInstance
            requestRate = Int(3600 * settings.cycleTime/(settings.cycleTime + settings.cycleBreak) / requestPeriod)
        }
    }
    
    dynamic var requestRate: Int = 0
    
    var email = "" {
        didSet {
            username = email.componentsSeparatedByString("@")[0]
            stats.email = self.email
        }
    }
    dynamic var username = ""
    
    var ready: Bool {
        return !fut16.sessionId.isEmpty
    }
    
    func resetStats() {
        stats.reset()
    }
}