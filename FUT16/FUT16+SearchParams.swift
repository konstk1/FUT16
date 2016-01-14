//
//  FUT16+SearchParams.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 1/14/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation

extension FUT16 {
    public class ItemParams {
        var level: String
        var minPrice: UInt
        var maxPrice: UInt
        var minBin: UInt
        var maxBin: UInt
        var startRecord: UInt
        var numRecords: UInt
        
        private static let maxRecords: UInt = 50
        
        init(level: String = "", minPrice: UInt = 0, maxPrice: UInt = 0, minBin: UInt = 0, maxBin: UInt = 0, startRecord: UInt = 0, numRecords: UInt = PlayerParams.maxRecords) {
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
                var url: String = "transfermarket?"
                
                numRecords = numRecords == 0 ? 1 : numRecords       // minimum number of records is 1
                url += "num=\(numRecords)"
                
                // other optional parameters
                url +=    level.isEmpty ? "" : "&lev=\(level)"
                url +=    minPrice == 0 ? "" : "&micr=\(minPrice)"
                url +=    maxPrice == 0 ? "" : "&macr=\(maxPrice)"
                url +=      minBin == 0 ? "" : "&minb=\(minBin)"
                url +=      maxBin == 0 ? "" : "&maxb=\(maxBin)"
                url += startRecord == 0 ? "" : "&start=\(startRecord)"
                
                return url
            }
        }
    }
    
    public class PlayerParams: ItemParams {
        var playerId: String
        var nationality: String
        var league: String
        var team: String
        
        init(playerId: String = "", nationality: String = "", league: String = "", team: String = "", level: String = "", minPrice: UInt = 0, maxPrice: UInt = 0, minBin: UInt = 0, maxBin: UInt = 0, startRecord: UInt = 0, numRecords: UInt = PlayerParams.maxRecords) {
            self.playerId = playerId
            self.nationality = nationality
            self.league = league
            self.team = team
            
            super.init(level: level, minPrice: minPrice, maxPrice: maxPrice, minBin: minBin, maxBin: maxBin, startRecord: startRecord, numRecords: numRecords)
        }
        
        override var urlPath: String {
            get {
                var url = super.urlPath + "&type=player"
                
                url +=    playerId.isEmpty ? "" : "&maskedDefId=\(playerId)"
                url += nationality.isEmpty ? "" : "&nat=\(nationality)"
                url +=      league.isEmpty ? "" : "&leag=\(league)"
                url +=        team.isEmpty ? "" : "&team=\(team)"
                
                print(url)

                return url
            }
        }
    } // end TransferPlayerSearch
}