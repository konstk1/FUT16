//
//  FUT16+Item.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 1/22/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation
import SwiftyJSON

extension FUT16 {
    // https://utas.s3.fut.ea.com/ut/game/fifa16/purchased/items
    
//    itemData: [{id: 103278371798, timestamp: 1453492267, formation: "f433", untradeable: false, assetId: 0,…},…]
//      0: {id: 103278371798, timestamp: 1453492267, formation: "f433", untradeable: false, assetId: 0,…}
//      1: {id: 103278395139, timestamp: 1453492323, formation: "f433", untradeable: false, assetId: 0,…}
//      2: {id: 103278407181, timestamp: 1453492339, formation: "f433", untradeable: false, assetId: 0,…}
//      3: {id: 103278448119, timestamp: 1453492262, formation: "f433", untradeable: false, assetId: 0,…}
//      4: {id: 103278469093, timestamp: 1453492347, formation: "f433", untradeable: false, assetId: 0,…}
//    
    // https://utas.s3.fut.ea.com/ut/game/fifa16/item
    // {"itemData":[{"id":"103278407181","pile":"trade"}]}
    
    public func sendItemsToTransferList() {
        getPurchasedItems { (itemsJson) -> () in
            guard itemsJson.count > 0 else { return }
            
            var items = [[String : String]]()
            itemsJson.forEach({ (key, item) -> () in
                items.append(["id": item["id"].stringValue,
                              "pile" : "trade"])
            })
            
            let parameters = ["itemData" : items]
            
            self.requestForPath("item", withParameters: parameters, encoding: .JSON, methodOverride: "PUT", completion: { (json) -> Void in
                print(json)
            })
        }
    }
    
    public func getPurchasedItems(completion: (itemsJson: JSON)->()) {
        requestForPath("purchased/items", methodOverride: "GET") { (json) -> Void in
            json["itemData"].forEach({ (key, json) -> () in
                print("\(key) - \(json["id"])")
            })
            completion(itemsJson: json["itemData"])
        }
    }
}