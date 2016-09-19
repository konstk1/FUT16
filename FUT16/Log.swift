//
//  Log.swift
//  FUT16
//
//  Created by Kon on 2/10/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Cocoa

open class Log {
    static open var printToConsole = true
    
    static fileprivate let viewController = NSApplication.shared().mainWindow!.windowController!.contentViewController as! ViewController
    
    class func print(_ items: Any..., separator: String = "", terminator: String = "\n") {
        var str = ""
        
        for item in items {
            str += String(describing: item) + separator
        }
        str += terminator
        
        viewController.log(str)
        
        if printToConsole {
            Swift.print(str, terminator: "")
        }
    }
}
