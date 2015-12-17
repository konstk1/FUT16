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
    
    var loginUrl: URLStringConvertible = "https://www.easports.com/fifa/ultimate-team/web-app"
    let baseShowoffUrl: URLStringConvertible = "https://www.easports.com/iframe/fut16/?locale=en_US&baseShowoffUrl=https%3A%2F%2Fwww.easports.com%2Ffifa%2Fultimate-team%2Fweb-app%2Fshow-off&guest_app_uri=http%3A%2F%2Fwww.easports.com%2Ffifa%2Fultimate-team%2Fweb-app"
    let acctInfoUrl: URLStringConvertible = "https://www.easports.com/iframe/fut16/p/ut/game/fifa16/user/accountinfo?sku=FUT16WEB&returningUserGameYear=2015&_1450386498000"
    
    let jSessionCookieUrl = NSURL(string: "https://signin.ea.com/p/JSESSIONID")!
    
    private var EASW_ID = ""
    private var personaId = ""

    init() {
        cfg.HTTPCookieStorage = cookieStoreage
        cfg.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicy.Always

        alamo = Alamofire.Manager.sharedInstance
//        alamo.delegate.taskWillPerformHTTPRedirection = { (session: NSURLSession, task: NSURLSessionTask, response: NSHTTPURLResponse, request: NSURLRequest) in
////            print("Redirect: \(request.URLString)")
//            return request
//        }
    }
    
    func login(email: String, password: String) {
        alamo.request(.GET, loginUrl).response { (request, response, data, error) -> Void in
            self.loginUrl = response!.URL!
            if self.loginUrl.URLString.containsString("web-app") {
                print("Already Logged In.")
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
                print(responseString)
                if responseString.containsString("Submit Security Code") {
                    print("Enter Security Code!")
                    // update login URL to sequence 2
                    self.loginUrl = response!.URL!
                } else {
                    print("Invalid login!")
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
            print(response)
            print(String(data: data!, encoding: NSUTF8StringEncoding))
        }
    }
    
    func getEaswId() {
        alamo.request(.GET, baseShowoffUrl).response {(request, response, data, error) -> Void in
            self.EASW_ID = self.extractEaswIdFromString(data!.string!)
            print("EASW_ID = \(self.EASW_ID)")
            self.getAcctInfo()
        }
    }
    
    func getAcctInfo() {
        let headers = ["Easw-Session-Data-Nucleus-Id" : EASW_ID,
                       "X-UT-Embed-Error" : "true",
                       "X-UT-Route" : "https://utas.s3.fut.ea.com:443" ]
        
        alamo.request(.GET, acctInfoUrl, headers: headers).responseJSON { (response) -> Void in
            guard let json = response.result.value else { return }
            let infoJson = JSON(json)

            
            self.personaId = infoJson["userAccountInfo"]["personas"][0]["personaId"].stringValue
            print("Persona ID = \(self.personaId)")
        }

    }
    
    
    private func printCookies() {
        guard let cookies = cookieStoreage.cookies else {
            print("Cookies: None")
            return
        }
        
        print("Cookies:")
    
        print(NSHTTPCookie.requestHeaderFieldsWithCookies(cookies))
    }
    
    private func extractEaswIdFromString(string: String) -> String {
        // current format:
        //        garbage
        //        var EASW_ID = '2415964099';
        //        garbage

        let components1 = string.componentsSeparatedByString("EASW_ID = '")
        let components2 = components1[1].componentsSeparatedByString("'")
        return components2[0]
    }
}

extension NSData {
    var string: String? {
        get {
            return String(data: self, encoding: NSUTF8StringEncoding)
        }
    }
}