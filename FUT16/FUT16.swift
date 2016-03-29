//
//  FUT16.swift
//  FUT16
//
//  Created by Kon on 12/15/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import Alamofire

public class FUT16 {
    
    private let cfg = NSURLSessionConfiguration.ephemeralSessionConfiguration()
    
    let alamo: Manager!
    
    var email: String = ""
    var user: String { return email.componentsSeparatedByString("@")[0] }
    
    var loginUrl: URLStringConvertible!
    let futUrl: URLStringConvertible = "https://utas.s3.fut.ea.com/ut/game/fifa16/"
    
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

        var defaultHeaders = Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders ?? [:]
        defaultHeaders["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36"
        defaultHeaders["Connection"] = "keep-alive"
        defaultHeaders["Host"] = "www.easports.com"
        
        cfg.HTTPAdditionalHeaders = defaultHeaders
        
        alamo = Alamofire.Manager(configuration: cfg)
    }
}