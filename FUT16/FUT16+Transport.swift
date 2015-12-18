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
    func fetchDataFromPath(urlPath: String) {
        let url: URLStringConvertible = futUrl.URLString + urlPath
        
        let headers = ["X-UT-SID" : getSessionId(),
                       "X-HTTP-Method-Override" : "GET"]
        
        alamo.request(.POST, url, headers: headers).responseJSON { (response) -> Void in
            print(JSON(response))
        }
    }
}
