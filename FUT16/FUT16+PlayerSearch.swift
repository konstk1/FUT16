//
//  FUT16+PlayerSearch.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 12/18/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import Alamofire

// Search player format
// https://utas.s3.fut.ea.com/ut/game/fifa16/

// Bid
// https://utas.s3.fut.ea.com/ut/game/fifa16/
//private let transferSearchPath: URLStringConvertible = "transfermarket?maxb=400&micr=150&start=0&macr=200&minb=300&maskedDefId=156616&num=16&type=player"
//private let bidPath = "trade/1187858658/bid"


extension FUT16 {
    public struct PlayerParams {
        var playerId: String
        var nationality: String
        var league: String
        var team: String
        var level: String
        var minPrice: UInt
        var maxPrice: UInt
        var minBin: UInt
        var maxBin: UInt
        var startRecord: UInt
        var numRecords: UInt
        
//        nat:54    brazil
//        team:5    chelsea
//        lev:gold
//        leag:13   BPL
        
        private static let maxRecords: UInt = 50
        
        init(playerId: String = "", nationality: String = "", league: String = "", team: String = "", level: String = "", minPrice: UInt = 0, maxPrice: UInt = 0, minBin: UInt = 0, maxBin: UInt = 0, startRecord: UInt = 0, numRecords: UInt = PlayerParams.maxRecords) {
            self.playerId = playerId
            self.nationality = nationality
            self.league = league
            self.team = team
            self.level = level
            self.minPrice = minPrice
            self.maxPrice = maxPrice
            self.minBin = minBin
            self.maxBin = maxBin
            self.startRecord = startRecord
            self.numRecords = numRecords
        }
        
        var urlPath: String {
            get {
                var url: String = "transfermarket?type=player"
                
                url =    !playerId.isEmpty ? url + "&maskedDefId=\(playerId)" : url
                url = !nationality.isEmpty ? url + "&nat=\(nationality)" : url
                url =      !league.isEmpty ? url + "&leag=\(league)" : url
                url =        !team.isEmpty ? url + "&team=\(team)" : url
                url =       !level.isEmpty ? url + "$lev=\(level)" : url
                
                url =    minPrice > 0 ? url + "&micr=\(minPrice)" : url
                url =    maxPrice > 0 ? url + "&macr=\(maxPrice)" : url
                url =      minBin > 0 ? url + "&minb=\(minBin)" : url
                url =      maxBin > 0 ? url + "&maxb=\(maxBin)" : url
                url = startRecord > 0 ? url + "&start=\(startRecord)" : url
                url =  numRecords > 0 ? url + "&num=\(numRecords)" : url
                return url
            }
        }
    } // end TransferPlayerSearch
    
    public func searchForPlayer(playerParams: PlayerParams) {
        requestForPath(playerParams.urlPath) { (json) -> Void in
//            print(json)
            if json["auctionInfo"].count > 0 {
                json["auctionInfo"].forEach { (key, json) in print("\(key) - \(json["buyNowPrice"])") }
            } else {
                print("Nothing found.")
            }
        }
    }
    
    public func findBinForPlayerId(playerId: String = "", nationality: String = "", league: String = "", team: String = "", level: String = "", maxBin: UInt, maxPrice: UInt = 0, completion: (auctions: [String : String]) -> Void) {
        let params = PlayerParams(playerId: playerId, nationality: nationality, league: league, team: team, level: level, maxBin: maxBin, maxPrice: maxPrice)
        print(params.urlPath)
        requestForPath(params.urlPath) { (json) -> Void in
            var auctions = [String : String]()
            if json["auctionInfo"].count > 0 {
                json["auctionInfo"].forEach{ (key, json) in
                    auctions[json["tradeId"].stringValue] = json["buyNowPrice"].stringValue
                }
            } else if json["code"].stringValue == "401" {
                print("Expired session...renewing...")
//                self.retrieveSessionId()
                // TODO: if error repeats more than X times in a row, exit
                exit(0)
            } else {
//                print(json)
                print("Nothing found.")
            }
            completion(auctions: auctions)
        }
    }
}
// Format:

//auctionInfo: [{tradeId: 1219355173,…}, {tradeId: 1219349619,…}, {tradeId: 1219364321,…}, {tradeId: 1219370322,…},…]
//0: {tradeId: 1219355173,…}
//bidState: "none"
//buyNowPrice: 63000
//confidenceValue: 100
//currentBid: 0
//expires: 33
//itemData: {id: 102327832878, timestamp: 1450582409, formation: "f3412", untradeable: false, assetId: 156616,…}
//offers: 0
//sellerEstablished: 0
//sellerId: 0
//sellerName: "FIFA UT"
//startingBid: 62500
//tradeId: 1219355173
//tradeOwner: false
//tradeState: "active"
//watched: null