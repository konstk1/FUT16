//
//  FUT16+Login.swift
//  FUT16
//
//  Created by Kon on 1/18/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

private let webAppUrl = "https://www.easports.com/fifa/ultimate-team/web-app"
private let baseShowoffUrl: URLStringConvertible = "https://www.easports.com/iframe/fut16/?baseShowoffUrl=https%3A%2F%2Fwww.easports.com%2Ffifa%2Fultimate-team%2Fweb-app%2Fshow-off&guest_app_uri=http%3A%2F%2Fwww.easports.com%2Ffifa%2Fultimate-team%2Fweb-app&locale=en_US"
private let acctInfoUrl: URLStringConvertible = "https://www.easports.com/iframe/fut16/p/ut/game/fifa16/user/accountinfo?sku=FUT16WEB&returningUserGameYear=2015"
private let authUrl: URLStringConvertible = "https://www.easports.com/iframe/fut16/p/ut/auth"
private let validateUrl: URLStringConvertible = "https://www.easports.com/iframe/fut16/p/ut/game/fifa16/phishing/validate"

extension FUT16 {
    public func login(_ email: String, password: String, secretAnswer: String, completion: @escaping ()->()) {
        self.email = email
        loginUrl = webAppUrl
        phishingQuestionAnswer = secretAnswer
        loginCompletion = completion
        alamo.request(.GET, loginUrl).response { [unowned self] (request, response, data, error) -> Void in
            guard response != nil else {
                Log.print("No response")
                return
            }
            self.loginUrl = response!.url!
            if self.loginUrl.URLString.contains("web-app") {
                Log.print("Already Logged In.")
                self.authenticate()
            } else {
                self.sendUsernamePassword(email, password: password)
            }
        }
    }
    
    // TODO: Add logout
    // https://www.easports.com/fifa/logout?redirectUri=https%3A%2F%2Fwww.easports.com%2Ffifa%2F
    
    fileprivate func sendUsernamePassword(_ email: String, password: String) {        
        let parameters = ["email"    : email,
            "password" : password,
            "_eventId" : "submit"]
        
        alamo.request(.POST, loginUrl, parameters: parameters).response { [unowned self] (request, response, data, error) -> Void in
            if let responseString = String(data: data!, encoding: String.Encoding.utf8) {
                if responseString.contains("Submit Security Code") {
                    Log.print("Enter Security Code!")
                    // update login URL to sequence 2
                    self.loginUrl = response!.url!
                    
                } else {
                    Log.print("Login Failure: Invalid login")
                }
            }
        }
    }
    
    func sendAuthCode(_ authCode: String) {
        let parameters = ["twofactorCode" : authCode,
            "_trustThisDevice" : "on",
            "trustThisDevice" : "on",
            "_eventId" : "submit"]
        alamo.request(.POST, loginUrl ?? "", parameters: parameters).response { [unowned self] (request, response, data, error) -> Void in
            if self.loginUrl == nil {
                Log.print("Generating TOTP: \(authCode)")
            }
            else if response!.url!.URLString.URLString.contains(webAppUrl) {
                Log.print("Login Successfull. Authenticating Session...")
                self.authenticate()
            } else {
                Log.print("Login Failed: Invalid two factor code")
            }
        }
    }
    
    func authenticate() {
        alamo.request(.GET, baseShowoffUrl).response { [unowned self] (request, response, data, error) -> Void in
            self.EASW_ID = self.extractEaswIdFromString(data!.string!)
            if self.EASW_ID == "0" {
                Log.print("Login failure: EASW_ID")
                return
            }
            Log.print("EASW_ID: \(self.EASW_ID)")
            self.getAcctInfo()
        }
    }
    
    fileprivate func getAcctInfo() {
        let headers = ["Easw-Session-Data-Nucleus-Id" : EASW_ID,
            "X-UT-Embed-Error" : "true",
            "X-UT-Route" : "https://utas.s3.fut.ea.com:443" ]
        
        alamo.request(.GET, acctInfoUrl, headers: headers).responseJSON { [unowned self] (response) -> Void in
            guard let json = response.result.value else { return }
            let infoJson = JSON(json)
            
            self.personaName = infoJson["userAccountInfo"]["personas"][0]["personaName"].stringValue
            self.personaId = infoJson["userAccountInfo"]["personas"][0]["personaId"].stringValue
            Log.print("Persona: \(self.personaName), ID: \(self.personaId)")
            
            self.retrieveSessionId()
        }
    }
    
    func retrieveSessionId() {
        let headers = ["X-UT-Embed-Error" : "true",
            "X-UT-Route" : "https://utas.s3.fut.ea.com:443" ]
        
        let parameters:[String : AnyObject] = ["clientVersion": "1" as AnyObject,
            "gameSku" : "FFA16XBO" as AnyObject,
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
        
        alamo.request(.POST, authUrl, headers: headers, parameters: parameters, encoding: .json).responseJSON { [unowned self] (response) -> Void in
            guard let json = response.result.value else {
                Log.print("Retrieve failed: \(response.response)")
                return
            }
            self.sessionId = JSON(json)["sid"].stringValue
            Log.print("Session ID: \(self.sessionId)")
            
            // TODO: ask for question and only retrieve token if necessary
            self.retrievePhishingToken()
        }
    }
    
    fileprivate func retrievePhishingToken() {
        let headers = ["Content-Type" : "application/x-www-form-urlencoded",
            "Easw-Session-Data-Nucleus-Id" : EASW_ID,
            "X-UT-SID" : sessionId,
            "X-UT-Embed-Error" : "true",
            "X-UT-Route" : "https://utas.s3.fut.ea.com:443" ]
        
        let parameters = ["answer" : phishingQuestionAnswer.md5()]
        
        alamo.request(.POST, validateUrl, headers: headers, parameters: parameters).responseJSON { [unowned self] (response) -> Void in
            guard let json = response.result.value else { return }
            self.phishingToken = JSON(json)["token"].stringValue
            
            guard !self.phishingToken.isEmpty else {
                Log.print ("Failed to get phishing token.")
                return
            }
            
            Log.print("Phishing Token: \(self.phishingToken)")
            // this is last step in the login process, mark session as valid
            self.isSessionValid = true
            
            self.getUserInfo()
        }
    }
}

// Helpers
extension FUT16 {
    fileprivate func extractEaswIdFromString(_ string: String) -> String {
        // current format:
        //        garbage
        //        var EASW_ID = '2415964099';
        //        garbage
        
        let components1 = string.components(separatedBy: "EASW_ID = '")
        if components1.count >= 2 {
            let components2 = components1[1].components(separatedBy: "'")
            return components2[0]
        } else {
            return "0"
        }
    }
}

extension String {
    func md5() -> String {
        var ctx = MD5_CTX()
        MD5ea_Init(&ctx)
        let data = self.data(using: String.Encoding.utf8)
        MD5ea_Update(&ctx, (data! as NSData).bytes, UInt(data!.count))
        
        let result = [UInt8](repeating: 0, count: 16)
        let pointer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer(mutating: result)
        MD5ea_Final(pointer, &ctx)
        
        return result.reduce("") { $0 + String(format:"%02x", $1) }
    }
}

extension Data {
    var string: String? {
        get {
            return String(data: self, encoding: String.Encoding.utf8)
        }
    }
}
