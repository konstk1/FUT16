//
//  FUT16+PlayerSearch.swift
//  FUT16
//
//  Created by Kon on 12/18/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import SwiftyJSON

extension FUT16 {
    public struct AuctionInfo: CustomStringConvertible {
        var tradeId = ""
        var expiresIn: UInt = 0
        var buyNowPrice: UInt = 0
        var isRare = false
        var subTypeId: UInt = 0
        
        init(fromJson json: JSON) {
            tradeId = json["tradeId"].stringValue
            expiresIn = json["expires"].uInt ?? 0
            buyNowPrice = json["buyNowPrice"].uInt ?? 0
            isRare = json["itemData"]["rareflag"].boolValue
            subTypeId = json["itemData"]["cardsubtypeid"].uInt ?? 0
        }
        
        public var description: String {
            return "Type: \(subTypeId) - \(isRare) BIN: \(buyNowPrice) Expires: \(expiresIn)"
        }
    }
    
    public func findAuctionsForItem(params: ItemParams, completion: (auctions: [AuctionInfo], error: FutError) -> Void) {
//        Log.print(params.urlPath)
        requestForPath(params.urlPath) { (json) -> Void in
            var auctions = [AuctionInfo]()
            var error = FutError.None
            let errorCode = json["code"].stringValue
//            Log.print("Error Code: \(errorCode)")
            
            if json["auctionInfo"].count > 0 {
                json["auctionInfo"].forEach{ (key, json) in
                    let auction = AuctionInfo(fromJson: json)
                    auctions.append(auction)
//                    Log.print(auction)
                }
//                Log.print(json["auctionInfo"])
            } else if errorCode == "401" {
                error = .ExpiredSession
            } else if errorCode == "500" {
                error = .InternalServerError
            }
            
            completion(auctions: auctions, error: error)
        }
    }
}