//
//  FUT16.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 12/15/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import Alamofire

class FUT16 {
    
    let cfg = NSURLSessionConfiguration.defaultSessionConfiguration()
    let cookieStoreage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
    let alamo: Manager!
    
    var loginUrl: URLStringConvertible!
    let jSessionCookieUrl = NSURL(string: "https://signin.ea.com/p/JSESSIONID")!

    init() {
        cfg.HTTPCookieStorage = cookieStoreage
        cfg.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicy.Always

        alamo = Alamofire.Manager.sharedInstance
    }
    
    func login(email: String, password: String) {
        let url = "https://www.easports.com/fifa/ultimate-team/web-app"
        
        alamo.request(.GET, url).response { (request, response, data, error) -> Void in
            self.loginUrl = response!.URL!
            if self.loginUrl.URLString.containsString("web-app") {
                print("Already Logged In.")
                self.printCookies()
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
    
    
    private func printCookies() {
        guard let cookies = cookieStoreage.cookies else {
            print("Cookies: None")
            return
        }
        
        print("Cookies:")
    
        print(NSHTTPCookie.requestHeaderFieldsWithCookies(cookies))
    }
}