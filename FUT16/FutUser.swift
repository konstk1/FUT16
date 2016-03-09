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
    
    dynamic lazy var stats: TraderStats = { [unowned self] in return TraderStats(email: self.email) }()
    
    var email = "" {
        didSet {
            username = email.componentsSeparatedByString("@")[0]
            stats = TraderStats(email: self.email)
        }
    }
    dynamic var username = ""
    
    var ready: Bool {
        return !fut16.sessionId.isEmpty
    }
    
    func resetStats() {
        stats = TraderStats(email: email)
    }
}