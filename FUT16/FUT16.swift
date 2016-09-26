//
//  FUT16.swift
//  FUT16
//
//  Created by Kon on 12/15/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import Alamofire

class FUT16 {
    
    fileprivate let cfg = URLSessionConfiguration.ephemeral
    
    let alamo: SessionManager!
    
    var email: String = ""
    var user: String { return email.components(separatedBy: "@")[0] }
    
    var loginUrl: String!
    let futUrl: String = "https://utas.external.s3.fut.ea.com/ut/game/fifa17/"
    
    // supplied by user
    var  phishingQuestionAnswer = ""
    
    var EASW_ID = ""
    var personaName = ""
    var personaId = ""
    
    var sessionId = ""
    var phishingToken = ""
    
    var coinFunds = ""
    
    var isSessionValid = false
    
    var loginCompletion: (()->())?
    
    var coinsBalance: Int {
        get {
            return Int(coinFunds) ?? -1
        }
    }

    public init() {
        cfg.timeoutIntervalForRequest = 20.0

        var defaultHeaders = [String:String]()
        defaultHeaders["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36"
        defaultHeaders["Connection"] = "keep-alive"
        defaultHeaders["Host"] = "www.easports.com"
        
        cfg.httpAdditionalHeaders = defaultHeaders
        
        alamo = Alamofire.SessionManager(configuration: cfg)
    }
}
