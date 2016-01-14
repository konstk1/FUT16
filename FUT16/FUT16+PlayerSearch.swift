//
//  FUT16+PlayerSearch.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 12/18/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import Alamofire

extension FUT16 {    
    public func findAuctionsForPlayer(params: PlayerParams, completion: (auctions: [String : String], error: FutError) -> Void) {
//        print(params.urlPath)
        requestForPath(params.urlPath) { (json) -> Void in
            var auctions = [String : String]()
            var error = FutError.None
            let errorCode = json["code"].stringValue
            //print("Error Code: \(errorCode)")
            
            if json["auctionInfo"].count > 0 {
                json["auctionInfo"].forEach{ (key, json) in
                    auctions[json["tradeId"].stringValue] = json["buyNowPrice"].stringValue
                }
            } else if errorCode == "401" {
                error = .ExpiredSession
            } else if errorCode == "500" {
                error = .InternalServerError
            }
            
            completion(auctions: auctions, error: error)
        }
    }
}