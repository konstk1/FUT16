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
    
    let jSessionCookieUrl = NSURL(string: "https://signin.ea.com/p/JSESSIONID")!

    init() {
        cfg.HTTPCookieStorage = cookieStoreage
        cfg.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicy.Always

        alamo = Alamofire.Manager.sharedInstance
        
        getLoginUrl()
    }
    
    func getLoginUrl() {
        let url = "https://www.easports.com/fifa/ultimate-team/web-app"
        let headers = ["Accept" : "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
                       "Accept-Encoding" : "gzip, deflate, sdch",
                        "Accept-Language":"en-US,en;q=0.8",
                        "Connection" : "keep-alive",
                        "Host" : "www.easports.com",
                        "Upgrade-Insecure-Requests" : "1",
                        "User-Agent" : "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36",
                        "X-FirePHP-Version" : "0.0.6"]
        
        alamo.request(.GET, url, headers: headers).response { (request, response, data, error) -> Void in
            print(response)
            self.printCookies()
            self.sendUsernamePassword(response!.URL!)
        }        
    }
    
    func sendUsernamePassword(url: URLStringConvertible) {
        guard let cookies = cookieStoreage.cookiesForURL(jSessionCookieUrl) else {
            print("JSESSIONID Cookie not found")
            return
        }
        
        var headers = ["Content-Type" : "application/x-www-form-urlencoded"
            Cookie:JSESSIONID=4DFAB11EDD64680DAB4E3AC447B4AD0E.eanshprdaccounts35; utag_main=_st:1450287259431$ses_id:1450286325763%3Bexp-session; __utma=103303007.221262541.1450285459.1450285459.1450285459.1; __utmc=103303007; __utmz=103303007.1450285459.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none)
            Host:signin.ea.com
        var headers = NSHTTPCookie.requestHeaderFieldsWithCookies(cookies)
        
        let parameters = ["email"    : "kostyan5@gmail.com",
                          "password" : "test",
                           "_eventId" : "submit"]
        
        alamo.request(.POST, url, parameters: parameters, headers: headers).response { (request, response, data, error) -> Void in
            print("Response: \(response)")
            self.printCookies()
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