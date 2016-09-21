//
//  FUT16+SearchParams.swift
//  FUT16
//
//  Created by Kon on 1/14/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation

extension FUT16 {
    open class ItemParams {
        var type: String
        var level: String
        var minPrice: UInt
        var maxPrice: UInt
        var minBin: UInt
        var maxBin: UInt
        var startRecord: UInt
        var numRecords: UInt
        
        fileprivate static let maxRecords: UInt = 16 //50
        
        fileprivate init(type: String, level: String = "", minPrice: UInt = 0, maxPrice: UInt = 0, minBin: UInt = 0, maxBin: UInt = 0, startRecord: UInt = 0, numRecords: UInt = PlayerParams.maxRecords) {
            self.type = type
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
                url +=     type.isEmpty ? "" : "&type=\(type)"
                url +=    minPrice == 0 ? "" : "&micr=\(minPrice)"
                url +=    maxPrice == 0 ? "" : "&macr=\(maxPrice)"
                url +=      minBin == 0 ? "" : "&minb=\(minBin)"
                url +=      maxBin == 0 ? "" : "&maxb=\(maxBin)"
                url += startRecord == 0 ? "" : "&start=\(startRecord)"
                
                return url
            }
        }
    }
    
    open class PlayerParams: ItemParams {
        var playerId: String
        var nationality: String
        var league: String
        var team: String
        
        init(playerId: String = "", nationality: String = "", league: String = "", team: String = "", level: String = "", minPrice: UInt = 0, maxPrice: UInt = 0, minBin: UInt = 0, maxBin: UInt = 0, startRecord: UInt = 0, numRecords: UInt = PlayerParams.maxRecords) {
            self.playerId = playerId
            self.nationality = nationality
            self.league = league
            self.team = team
            
            super.init(type: "player", level: level, minPrice: minPrice, maxPrice: maxPrice, minBin: minBin, maxBin: maxBin, startRecord: startRecord, numRecords: numRecords)
        }
        
        override var urlPath: String {
            get {
                var url = super.urlPath
                
                url +=    playerId.isEmpty ? "" : "&maskedDefId=\(playerId)"
                url += nationality.isEmpty ? "" : "&nat=\(nationality)"
                url +=      league.isEmpty ? "" : "&leag=\(league)"
//                url +=        team.isEmpty ? "" : "&team=\(team)"
                
                return url
            }
        }
    }
    
    open class ConsumableParams: ItemParams {

        var category: String
        
        init(category: String, level: String = "", minPrice: UInt = 0, maxPrice: UInt = 0, minBin: UInt = 0, maxBin: UInt = 0, startRecord: UInt = 0, numRecords: UInt = PlayerParams.maxRecords) {

            self.category = category
            
            super.init(type: "development", level: level, minPrice: minPrice, maxPrice: maxPrice, minBin: minBin, maxBin: maxBin, startRecord: startRecord, numRecords: numRecords)
        }
        
        // transfermarket?minb=600&maxb=650&cat=fitness&num=16&lev=gold&start=0&type=development
        override var urlPath: String {
            get {
                let url = super.urlPath + "&type=development" + "&cat=\(category)"
                return url
            }
        }
    }
}
