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

class FUT16 {
    
    private let cfg = NSURLSessionConfiguration.defaultSessionConfiguration()
    private let cookieStoreage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
    
    let alamo: Manager!
    
    private var loginUrl: URLStringConvertible!
    private let webAppUrl = "https://www.easports.com/fifa/ultimate-team/web-app"
    private let baseShowoffUrl: URLStringConvertible = "https://www.easports.com/iframe/fut16/?locale=en_US&baseShowoffUrl=https%3A%2F%2Fwww.easports.com%2Ffifa%2Fultimate-team%2Fweb-app%2Fshow-off&guest_app_uri=http%3A%2F%2Fwww.easports.com%2Ffifa%2Fultimate-team%2Fweb-app"
    private let acctInfoUrl: URLStringConvertible = "https://www.easports.com/iframe/fut16/p/ut/game/fifa16/user/accountinfo?sku=FUT16WEB&returningUserGameYear=2015&_1450386498000"
    private let authUrl: URLStringConvertible = "https://www.easports.com/iframe/fut16/p/ut/auth"
    let futUrl: URLStringConvertible = "https://utas.s3.fut.ea.com/ut/game/fifa16/"
    
    private var EASW_ID = ""
    private var personaName = ""
    private var personaId = ""
    
    private var sessionId = ""
    
    func getSessionId() -> String {
        return sessionId
    }

    init() {
        cfg.HTTPCookieStorage = cookieStoreage
        cfg.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicy.Always
        
//        for cookie in cookieStoreage.cookies! {
//            cookieStoreage.deleteCookie(cookie)
//        }

        alamo = Alamofire.Manager.sharedInstance
    }
    
    func login(email: String, password: String) {
        loginUrl = webAppUrl
        alamo.request(.GET, loginUrl).response { (request, response, data, error) -> Void in
            self.loginUrl = response!.URL!
            if self.loginUrl.URLString.containsString("web-app") {
                print("Already Logged In.")
                self.authenticate()
            } else {
                self.sendUsernamePassword(email, password: password)
            }
        }
    }
    
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
            
//            self.getSessionId()
        }
    }
    
    private func getSessionId() {
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
        
        alamo.request(.POST, authUrl, headers: headers, parameters: parameters, encoding: .JSON).responseJSON { (response) -> Void in
            guard let json = response.result.value else { return }
            self.sessionId = JSON(json)["sid"].stringValue
            print("Session ID: \(self.sessionId)")
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

extension NSData {
    var string: String? {
        get {
            return String(data: self, encoding: NSUTF8StringEncoding)
        }
    }
}