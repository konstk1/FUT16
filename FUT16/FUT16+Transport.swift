//
//  FUT16+Transport.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 12/17/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

// generic transport functions
extension FUT16 {
    func requestForPath(urlPath: String, withParameters parameters: [String : AnyObject]? = nil, encoding: ParameterEncoding = .URL, methodOverride: String = "GET", completion: (json: JSON) -> Void) {
        
        guard isSessionValid else {
            print("Waing for valid session...")
            return
        }
        
        let url: URLStringConvertible = futUrl.URLString + urlPath
        
        let headers = ["X-UT-SID" : sessionId,
                       "X-UT-PHISHING-TOKEN" : phishingToken,
                       "X-HTTP-Method-Override" : methodOverride,
                       "X-UT-Embed-Error" : "true"]
        
        alamo.request(.POST, url, headers: headers, parameters: parameters, encoding: encoding).responseJSON { (response) -> Void in
            switch response.result {
            case .Success:
                completion(json: JSON(response.result.value!))
            case .Failure (let error):
                completion(json: "")
                print("Failed to fetch JSON (error: \(error)")
            }
        }
    }
}
