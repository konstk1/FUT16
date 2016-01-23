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
                json["itemData"].forEach({ (key, json) -> () in
                    print("\(key) - \(json["id"]) - \(json["pile"]) - \(json["success"])")
                })
            })
        }
    }
    
    public func getPurchasedItems(completion: (itemsJson: JSON)->()) {
        requestForPath("purchased/items", methodOverride: "GET") { (json) -> Void in
            completion(itemsJson: json["itemData"])
        }
    }
}