//
//  FutDatabase.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 9/26/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

class FutDatabase {
    fileprivate static let databaseUrl = "https://www.easports.com/fifa/ultimate-team/api/fut/item"
    
    static func getPlayerInfo(baseId: String, completion: @escaping (PlayerInfo?)->()) {
        let params = ["jsonParamObject": "{\"baseid\":\"\(baseId)\"}"]
        
        Alamofire.request(databaseUrl, parameters: params, encoding: URLEncoding.default).responseJSON { (response) in
//            print(response.request!.url!.absoluteString)
            
            guard let result = response.result.value else {
                completion(nil)
                return
            }
            let json = JSON(result)["items"]
            
            guard json.count > 0 else {
                completion(nil)
                return
            }
            
            let item = json[0]
            let playerInfo = PlayerInfo(json: item)
            completion(playerInfo)
        }
    }
}

class PlayerInfo {
    var firstName  = ""
    var lastName   = ""
    var commonName = ""
    var league     = ""
    var team       = ""
    var nation     = ""
    var rating     = 0
    
    var imageUrl   = ""
    
    init(json: JSON) {
        firstName  = json["firstName"].stringValue
        lastName   = json["lastName"].stringValue
        commonName = json["commonName"].stringValue
        league     = "\(json["league"]["name"]) (\(json["league"]["abbrName"]))"
        team       = json["club"]["abbrName"].stringValue
        nation     = json["nation"]["abbrName"].stringValue
        rating     = json["rating"].intValue
        
        imageUrl   = json["headshotImgUrl"].stringValue
    }
}
