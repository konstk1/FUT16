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
                
                url +=    playerId.isEmpty ? "" : "&maskedDefId=\(playerId)"
                url += nationality.isEmpty ? "" : "&nat=\(nationality)"
                url +=      league.isEmpty ? "" : "&leag=\(league)"
                url +=        team.isEmpty ? "" : "&team=\(team)"
                url +=       level.isEmpty ? "" : "&lev=\(level)"
                
                url +=    minPrice == 0 ? "" : "&micr=\(minPrice)"
                url +=    maxPrice == 0 ? "" : "&macr=\(maxPrice)"
                url +=      minBin == 0 ? "" : "&minb=\(minBin)"
                url +=      maxBin == 0 ? "" : "&maxb=\(maxBin)"
                url += startRecord == 0 ? "" : "&start=\(startRecord)"
                url +=  numRecords == 0 ? "" : "&num=\(numRecords)"
                return url
            }
        }
    } // end TransferPlayerSearch
    
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