//
//  FUT16.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 12/15/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
//import CryptoSwift

public class FUT16 {
    
    private let cfg = NSURLSessionConfiguration.defaultSessionConfiguration()
    private let cookieStoreage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
    
    let alamo: Manager!
    
    private var loginUrl: URLStringConvertible!
    private let webAppUrl = "https://www.easports.com/fifa/ultimate-team/web-app"
    private let baseShowoffUrl: URLStringConvertible = "https://www.easports.com/iframe/fut16/?baseShowoffUrl=https%3A%2F%2Fwww.easports.com%2Ffifa%2Fultimate-team%2Fweb-app%2Fshow-off&guest_app_uri=http%3A%2F%2Fwww.easports.com%2Ffifa%2Fultimate-team%2Fweb-app&locale=en_US"
    private let acctInfoUrl: URLStringConvertible = "https://www.easports.com/iframe/fut16/p/ut/game/fifa16/user/accountinfo?sku=FUT16WEB&returningUserGameYear=2015"
    private let authUrl: URLStringConvertible = "https://www.easports.com/iframe/fut16/p/ut/auth"
    private let validateUrl: URLStringConvertible = "https://www.easports.com/iframe/fut16/p/ut/game/fifa16/phishing/validate"
    let futUrl: URLStringConvertible = "https://utas.s3.fut.ea.com/ut/game/fifa16/"
    
    // supplied by user
    private var  phishingQuestionAnswer = ""
    
    private var EASW_ID = ""
    private var personaName = ""
    private var personaId = ""
    
    private(set) var sessionId = ""
    private(set) var phishingToken = ""
    
    var coinFunds = ""
    
    var isSessionValid = false
    
    var coinsBalance: Int {
        get {
            return Int(coinFunds) ?? -1
        }
    }

    public init() {
        cfg.HTTPCookieStorage = cookieStoreage
        cfg.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicy.Always
        cfg.timeoutIntervalForRequest = 2.0

//        for cookie in cookieStoreage.cookies! {
//            cookieStoreage.deleteCookie(cookie)
//        }

        var defaultHeaders = Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders ?? [:]
        defaultHeaders["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36"
        defaultHeaders["Connection"] = "keep-alive"
        defaultHeaders["Host"] = "www.easports.com"
        
        cfg.HTTPAdditionalHeaders = defaultHeaders
        
        alamo = Alamofire.Manager(configuration: cfg)
    }
    
    public func login(email: String, password: String, secretAnswer: String) {
        loginUrl = webAppUrl
        phishingQuestionAnswer = secretAnswer
        alamo.request(.GET, loginUrl).response { (request, response, data, error) -> Void in
            guard response != nil else {
                print("No response")
                return
            }
            self.loginUrl = response!.URL!
            if self.loginUrl.URLString.containsString("web-app") {
                print("Already Logged In.")
                self.authenticate()
            } else {
                self.sendUsernamePassword(email, password: password)
            }
        }
    }
    
    // TODO: Add logout
    // https://www.easports.com/fifa/logout?redirectUri=https%3A%2F%2Fwww.easports.com%2Ffifa%2F
    
    private func sendUsernamePassword(email: String, password: String) {
        let parameters = ["email"    : email,
                          "password" : password,
                           "_eventId" : "submit"]
        
        alamo.request(.POST, loginUrl, parameters: parameters).response { (request, response, data, error) -> Void in
            if let responseString = String(data: data!, encoding: NSUTF8StringEncoding) {
                if responseString.containsString("Submit Security Code") {
                    print("Enter Security Code!")
                    // update login URL to sequence 2
                    self.loginUrl = response!.URL!
                } else {
                    print("Login Failure: Invalid login")
                }
            }
        }
    }
    
    func sendAuthCode(authCode: String) {
        let parameters = ["twofactorCode" : authCode,
                          "_trustThisDevice" : "on",
                          "trustThisDevice" : "on",
                          "_eventId" : "submit"]
        alamo.request(.POST, loginUrl, parameters: parameters).response {(request, response, data, error) -> Void in
            if response!.URL!.URLString.URLString.containsString(self.webAppUrl) {
                print("Login Successfull. Authenticating Session...")
                self.authenticate()
            } else {
                print(response!.URL!.URLString)
                print(self.webAppUrl)
                print("Login Failed: Invalid two factor code")
            }
        }
    }
    
    func authenticate() {
        alamo.request(.GET, baseShowoffUrl).response {(request, response, data, error) -> Void in
            self.EASW_ID = self.extractEaswIdFromString(data!.string!)
            if self.EASW_ID == "0" {
                print("Login failure: EASW_ID")
                return
            }
            print("EASW_ID: \(self.EASW_ID)")
            self.getAcctInfo()
        }
    }
    
    private func getAcctInfo() {
        let headers = ["Easw-Session-Data-Nucleus-Id" : EASW_ID,
                       "X-UT-Embed-Error" : "true",
                       "X-UT-Route" : "https://utas.s3.fut.ea.com:443" ]
        
        alamo.request(.GET, acctInfoUrl, headers: headers).responseJSON { (response) -> Void in
            guard let json = response.result.value else { return }
            let infoJson = JSON(json)

            self.personaName = infoJson["userAccountInfo"]["personas"][0]["personaName"].stringValue
            self.personaId = infoJson["userAccountInfo"]["personas"][0]["personaId"].stringValue
            print("Persona: \(self.personaName), ID: \(self.personaId)")
            
            self.retrieveSessionId()
        }
    }
    
    func retrieveSessionId() {
        let headers = ["X-UT-Embed-Error" : "true",
                       "X-UT-Route" : "https://utas.s3.fut.ea.com:443" ]
        
        let parameters:[String : AnyObject] = ["clientVersion": "1",
                                                "gameSku" : "FFA16XBO",
                                                "identification" : ["authCode" : ""],
                                                "isReadOnly" : "false",
                                                "locale" : "en-US",
                                                "method" : "authcode",
                                                "nucleusPersonaDisplayName" : personaName,
                                                "nucleusPersonaId" : personaId,
                                                "nucleusPersonaPlatform" : "360",
                                                "priorityLevel" : "4",
                                                "sku" : "FUT16WEB"]
        
        // if fetching new session ID, marked previous as invalid until the fetching is done
        isSessionValid = false
        
        alamo.request(.POST, authUrl, headers: headers, parameters: parameters, encoding: .JSON).responseJSON { (response) -> Void in
            guard let json = response.result.value else { return }
            self.sessionId = JSON(json)["sid"].stringValue
            print("Session ID: \(self.sessionId)")
            
            // TODO: ask for question and only retrieve token if necessary
            self.retrievePhishingToken()
        }
    }
    
    private func retrievePhishingToken() {
        let headers = ["Content-Type" : "application/x-www-form-urlencoded",
                       "Easw-Session-Data-Nucleus-Id" : EASW_ID,
                       "X-UT-SID" : sessionId,
                       "X-UT-Embed-Error" : "true",
                       "X-UT-Route" : "https://utas.s3.fut.ea.com:443" ]

        let parameters = ["answer" : phishingQuestionAnswer.md5()]
        
        alamo.request(.POST, validateUrl, headers: headers, parameters: parameters).responseJSON { (response) -> Void in
            guard let json = response.result.value else { return }
            self.phishingToken = JSON(json)["token"].stringValue
            
            guard !self.phishingToken.isEmpty else {
                print ("Failed to get phishing token.")
                return
            }
            
            print("Phishing Token: \(self.phishingToken)")
            // this is last step in the login process, mark session as valid
            self.isSessionValid = true
            
            self.getUserInfo()
        }
    }
}

// Helpers
extension FUT16 {
    private func extractEaswIdFromString(string: String) -> String {
        // current format:
        //        garbage
        //        var EASW_ID = '2415964099';
        //        garbage
        
        let components1 = string.componentsSeparatedByString("EASW_ID = '")
        let components2 = components1[1].componentsSeparatedByString("'")
        return components2[0]
    }
    
    private func printCookies() {
        guard let cookies = cookieStoreage.cookies else {
            print("Cookies: None")
            return
        }
        
        print("Cookies:")
        
        print(NSHTTPCookie.requestHeaderFieldsWithCookies(cookies))
    }
}

extension String {
    func md5() -> String {
        var ctx = MD5_CTX()
        MD5ea_Init(&ctx)
        let data = self.dataUsingEncoding(NSUTF8StringEncoding)
        MD5ea_Update(&ctx, data!.bytes, UInt(data!.length))
        
        let result = [UInt8](count: 16, repeatedValue: 0)
        let pointer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer(result)
        MD5ea_Final(pointer, &ctx)
        
        return result.reduce("") { $0 + String(format:"%02x", $1) }
    }
}

extension NSData {
    var string: String? {
        get {
            return String(data: self, encoding: NSUTF8StringEncoding)
        }
    }
}