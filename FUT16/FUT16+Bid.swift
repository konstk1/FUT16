//
//  FUT16+Bid.swift
//  FUT16
//
//  Created by Kon on 12/20/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

extension FUT16 {
    func placeBidOnAuction(_ auctionId: String, amount: UInt, completion: @escaping (_ email: String, _ error: FutError) -> Void) {
        let bidUrl = "trade/\(auctionId)/bid"
        let parameters = ["bid" : amount as AnyObject]
        
        self.requestForPath(bidUrl, withParameters: parameters, encoding: JSONEncoding.default, methodOverride: "PUT") { [unowned self] (json) -> Void in
            let tradeId = json["auctionInfo"][0]["tradeId"].stringValue
            let funds = json["currencies"][0]["finalFunds"].stringValue
            let fundCurrency = json["currencies"][0]["name"].stringValue
            
            var error = FutError.none
            
            if fundCurrency == "COINS" {
                self.coinFunds = funds
            }
            if tradeId == "" {
                let errorCode = json["code"]
                switch errorCode {
                case "461":
                    error = .bidNotAllowed
                case "470":
                    error = .notEnoughCredit
                default:
                    Log.print(json)
                    error = .purchaseFailed
                }
            } else {
//                Log.print("Purchased \(tradeId) for \(amount) - \(json["auctionInfo"][0]["tradeState"]) (Bal: \(self.coinsBalance))")
            }
            
            completion(self.email, error)
        }
    }
    
    func searchForAuction(_ auctionId: String, completion: @escaping (JSON) -> Void) {
        let tradeSearchUrl = "trade/status?tradeIds=\(auctionId)"
        
        requestForPath(tradeSearchUrl) { (json) -> Void in
            completion(json)
        }
    }
}
