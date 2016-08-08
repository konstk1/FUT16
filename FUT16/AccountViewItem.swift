//
//  AccountViewItem.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 7/31/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Cocoa

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
    
    @IBOutlet weak var statusLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layer?.backgroundColor = NSColor.whiteColor().CGColor
    }
    
    override func awakeFromNib() {
        self.view.wantsLayer = true
    }
    
    @IBAction func loginPushed(sender: NSButton) {
        Log.print("Login: \(user.username)")
        user.fut16.login(user.email, password: user.password, secretAnswer: user.answer) {
            self.user.stats.coinsBalance = self.user.fut16.coinsBalance
            self.statusLabel.stringValue = "v"
            Log.print("Done")
        }
    }
    
    @IBAction func totpPushed(sender: NSButton) {
        totpLabel.stringValue = user.authCode
        user.fut16.sendAuthCode(user.authCode)
    }
    
    @IBAction func resetPushed(sender: NSButton) {
        user.resetStats()
    }
    
    @IBAction func onClick(sender: NSTextField) {
        print("On click")
    }
}
