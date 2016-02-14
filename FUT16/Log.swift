//
//  Log.swift
//  FUT16
//
//  Created by Kon on 2/10/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Cocoa

public class Log {
    static public var printToConsole = true
    
    static private let viewController = NSApplication.sharedApplication().mainWindow!.windowController!.contentViewController as! ViewController
    
    class func print(items: Any..., separator: String = "", terminator: String = "\n") {
        var str = ""
        
        for item in items {
            str += String(item) + separator
        }
        str += terminator
        
        viewController.log(str)
        
        if printToConsole {
            Swift.print(str, terminator: "")
        }
    }
}