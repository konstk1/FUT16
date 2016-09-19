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
        let garbageSet = CharacterSet(charactersIn: " \t")
        var futUsers = [FutUser]()
        do {
            let contents = try String(contentsOfFile: file)
            let lines = contents.components(separatedBy: "\n")
            for line in lines where !line.hasPrefix("//") {
                let tokens = line.components(separatedBy: "/")
                let user = FutUser()
                user.email = tokens[0].trimmingCharacters(in: garbageSet)
                user.password = tokens[1].trimmingCharacters(in: garbageSet)
                user.answer = tokens[2].trimmingCharacters(in: garbageSet)
                user.totpToken = tokens[3].trimmingCharacters(in: garbageSet)
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
