//
//  FUT16+Transport.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 12/17/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

// generic transport functions
extension FUT16 {
    func requestForPath(urlPath: String, withParameters parameters: [String : AnyObject]? = nil, encoding: ParameterEncoding = .URL, methodOverride: String = "GET", completion: (json: JSON) -> Void) {
        
        guard isSessionValid else {
            print("Waing for valid session...")
            return
        }
        
        let url: URLStringConvertible = futUrl.URLString + urlPath
        
        let headers = ["X-UT-SID" : sessionId,
                       "X-UT-PHISHING-TOKEN" : phishingToken,
                       "X-HTTP-Method-Override" : methodOverride,
                       "X-UT-Embed-Error" : "true"]
        
        alamo.request(.POST, url, headers: headers, parameters: parameters, encoding: encoding).responseJSON { (response) -> Void in
            switch response.result {
            case .Success:
                completion(json: JSON(response.result.value!))
            case .Failure (let error):
                completion(json: "")
                print("Failed to fetch JSON (error: \(error)")
            }
        }
    }
}

// POST https://utas.s3.fut.ea.com/ut/game/fifa16/user
//accountCreatedPlatformName: "360"
//actives: [{id: 102340706883, timestamp: 1450645529, formation: "f433", untradeable: true, assetId: 149,…},…]
//bidTokens: {}
//clubAbbr: "A T"
//clubName: "A Team"
//credits: 39598
//currencies: [{name: "COINS", funds: 39598, finalFunds: 39598}, {name: "POINTS", funds: 0, finalFunds: 0},…]
//0: {name: "COINS", funds: 39598, finalFunds: 39598}
//1: {name: "POINTS", funds: 0, finalFunds: 0}
//2: {name: "DRAFT_TOKEN", funds: 0, finalFunds: 0}
//divisionOffline: 1
//divisionOnline: 1
//draw: 0
//established: "1450645529"
//feature: {trade: 2}
//loss: 10
//personaId: 1721880717
//personaName: "TwelfthCannon68"
//purchased: false
//reliability: {reliability: 105, startedMatches: 16, finishedMatches: 15, matchUnfinishedTime: 0}
//finishedMatches: 15
//matchUnfinishedTime: 0
//reliability: 105
//startedMatches: 16
//seasonTicket: false
//squadList: {,…}
//trophies: 0
//unassignedPileSize: 0
//unopenedPacks: {preOrderPacks: 0, recoveredPacks: 0}
//preOrderPacks: 0
//recoveredPacks: 0
//won: 2
