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
    func fetchJsonFromPath(urlPath: String, completion: (json: JSON) -> Void) {
        let url: URLStringConvertible = futUrl.URLString + urlPath
        
        let headers = ["X-UT-SID" : getSessionId(),
                       "X-UT-PHISHING-TOKEN" : getPhishingToken(),
                       "X-HTTP-Method-Override" : "GET",
                       "X-UT-Embed-Error" : "true"]
        
        alamo.request(.POST, url, headers: headers).responseJSON { (response) -> Void in
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
