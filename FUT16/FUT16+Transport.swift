//
//  FUT16+Transport.swift
//  FUT16
//
//  Created by Kon on 12/17/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

// generic transport functions
extension FUT16 {
    @discardableResult
    func requestForPath(_ urlPath: String, withParameters parameters: [String : AnyObject]? = nil, encoding: ParameterEncoding = URLEncoding.default, methodOverride: String = "GET", completion: @escaping (_ json: JSON) -> Void) -> Request! {
        
        guard isSessionValid else {
            Log.print("Waiting for valid session...")
            completion("")
            return nil
        }
        
        let url = futUrl + urlPath
        
        let headers = ["X-UT-SID" : sessionId,
                       "X-UT-PHISHING-TOKEN" : phishingToken,
                       "X-HTTP-Method-Override" : methodOverride,
                       "X-UT-Embed-Error" : "true"]
        
        return alamo.request(url, method: .post, parameters: parameters, encoding: encoding, headers: headers).responseJSON { (response) -> Void in
            switch response.result {
            case .success:
                completion(JSON(response.result.value!))
            case .failure (let error):
                completion("")
                Log.print("Failed to fetch JSON (error: \(error)")
            }
        }
    }
    
    func getUserInfo() {
        requestForPath("user") { [unowned self] (json) -> Void in
            self.coinFunds = json["credits"].stringValue
            Log.print("Coins Balance: \(self.coinFunds)")
            self.loginCompletion?()
        }
    }
}
