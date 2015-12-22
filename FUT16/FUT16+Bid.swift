//
//  FUT16+Bid.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 12/20/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import SwiftyJSON

// POST URL: https://utas.s3.fut.ea.com/ut/game/fifa16/trade/1218165632/bid
// Params: {"bid":200}

extension FUT16 {
    func placeBidOnAuction(auctionId: String, ammount: UInt) {
        let bidUrl = "trade/\(auctionId)/bid"
        let parameters = ["bid" : ammount]
        
        self.requestForPath(bidUrl, withParameters: parameters, encoding: .JSON, methodOverride: "PUT") { (json) -> Void in
            let tradeId = json["auctionInfo"][0]["tradeId"].stringValue
            if tradeId == "" {
                print("Failed to purchase.")
                print(json)
            } else {
                print("Purchased \(tradeId) for \(ammount) - \(json["auctionInfo"][0]["tradeState"])")
            }
        }
    }
    
    func searchForAuction(auctionId: String, completion: (JSON) -> Void) {
        let tradeSearchUrl = "trade/status?tradeIds=\(auctionId)"
        
        requestForPath(tradeSearchUrl) { (json) -> Void in
            completion(json)
        }
    }
}

// Format:

//auctionInfo: [{tradeId: 1221506371,…}]
//0: {tradeId: 1221506371,…}
//bidState: "buyNow"
//buyNowPrice: 200
//confidenceValue: 100
//currentBid: 200
//expires: -1
//itemData: {id: 102344688961, timestamp: 1450658209, formation: "f3412", untradeable: false, assetId: 153275,…}
//offers: 0
//sellerEstablished: 0
//sellerId: 0
//sellerName: "FIFA UT"
//startingBid: 150
//tradeId: 1221506371
//tradeOwner: false
//tradeState: "closed"
//watched: false