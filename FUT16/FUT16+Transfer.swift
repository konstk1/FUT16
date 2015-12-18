//
//  FUT16+Transfer.swift
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
private let transferSearchPath: URLStringConvertible = "transfermarket?maxb=400&micr=150&start=0&macr=200&minb=300&maskedDefId=156616&num=16&type=player"
private let bidPath = "trade/1187858658/bid"


extension FUT16 {
    struct TransferPlayerSearch {
        var playerId: String
        var minPrice: UInt
        var maxPrice: UInt
        var minBin: UInt
        var maxBin: UInt
        var startRecord: UInt
        var numRecords: UInt
        
        private static let maxRecords: UInt = 50
        
        init(playerId: String = "0", minPrice: UInt = 0, maxPrice: UInt = 0, minBin: UInt = 0, maxBin: UInt = 0, startRecord: UInt = 0, numRecords: UInt = TransferPlayerSearch.maxRecords) {
            self.playerId = playerId
            self.minPrice = minPrice
            self.maxPrice = maxPrice
            self.minBin = minBin
            self.maxBin = maxBin
            self.startRecord = startRecord
            self.numRecords = numRecords
        }
        
        var urlPath: URLStringConvertible {
            get {
                var url: String = "transfermarket?type=player&maskedDefId=\(playerId)"
                url = minPrice > 0 ? url + "micr=\(minPrice)" : url
                url = maxPrice > 0 ? url + "macr=\(maxPrice)" : url
                url = minBin > 0 ? url + "minb=\(minPrice)" : url
                url = maxBin > 0 ? url + "maxb=\(minPrice)" : url
                url = startRecord > 0 ? url + "start=\(startRecord)" : url
                url = numRecords > 0 ? url + "num=\(numRecords)" : url
                return url
            }
        }
    } // end TransferPlayerSearch
    
    func transferSearch(playerId: String) {
        
    }
}