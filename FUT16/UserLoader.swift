//
//  UserLoader.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 7/31/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Foundation

class UserLoader {
    class func getUsers(from file: String) -> [FutUser]? {
        let garbageSet = NSCharacterSet(charactersInString: " \t")
        var futUsers = [FutUser]()
        do {
            let contents = try String(contentsOfFile: file)
            let lines = contents.componentsSeparatedByString("\n")
            for line in lines {
                let tokens = line.componentsSeparatedByString("/")
                let user = FutUser()
                user.email = tokens[0].stringByTrimmingCharactersInSet(garbageSet)
                user.password = tokens[1].stringByTrimmingCharactersInSet(garbageSet)
                user.answer = tokens[2].stringByTrimmingCharactersInSet(garbageSet)
                user.totpToken = tokens[3].stringByTrimmingCharactersInSet(garbageSet)
                futUsers.append(user)
            }
        } catch {
            print("Load error")
            return nil
        }
        
        print("Loaded \(futUsers.count) users")
        return futUsers
    }
}