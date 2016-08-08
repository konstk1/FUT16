//
//  AccountViewItem.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 7/31/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Cocoa

let colorLoggingIn = NSColor(red: 1, green: 1, blue: 0, alpha: 0.7)
let colorLoggedIn = NSColor(red: 0, green: 1, blue: 0, alpha: 0.7)
let colorPurchase = NSColor(red: 0, green: 1, blue: 1, alpha: 0.7)
let colorDefault = NSColor.whiteColor()

class AccountViewItem: NSCollectionViewItem {
    
    dynamic var user: FutUser! {
        didSet {
            guard viewLoaded else { return }
            usernameLabel.stringValue = user.email
            totpLabel.stringValue = user.authCode
        }
    }
    
    @IBOutlet weak var usernameLabel: NSTextField!
    @IBOutlet weak var totpLabel: NSTextField!
    @IBOutlet weak var loginButton: NSButton!
    
    @IBOutlet weak var search1HrLabel: NSTextField!
    @IBOutlet weak var search24HrLabel: NSTextField!
    @IBOutlet weak var purchaseCountLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setBackground(colorDefault)
    }
    
    override func awakeFromNib() {
        self.view.wantsLayer = true
    }
    
    func setBackground(color: NSColor) {
        self.view.layer?.backgroundColor = color.CGColor
    }
    
    @IBAction func loginPushed(sender: NSButton) {
        Log.print("Login: \(user.username)")
        self.setBackground(colorLoggingIn)
        user.fut16.login(user.email, password: user.password, secretAnswer: user.answer) {
            self.user.stats.coinsBalance = self.user.fut16.coinsBalance
            self.setBackground(colorLoggedIn)
        }
    }
    
    @IBAction func totpPushed(sender: NSButton) {
        totpLabel.stringValue = user.authCode
        user.fut16.sendAuthCode(user.authCode)
    }
    
    var i = 0
    
    @IBAction func resetPushed(sender: NSButton) {
        user.resetStats()
    }
}
