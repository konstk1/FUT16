//
//  AccountViewItem.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 7/31/16.
//  Copyright © 2016 Kon. All rights reserved.
//

import Cocoa

class AccountViewItem: NSCollectionViewItem {
    
    var user: FutUser? {
        didSet {
            guard viewLoaded else { return }
            usernameLabel.stringValue = user?.email ?? ""
            totpLabel.stringValue = user?.authCode ?? ""
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
        guard let user = user else { return }
        
        Log.print("Login: \(user.username)")
        user.fut16.login(user.email, password: user.password, secretAnswer: user.answer) {
//            user!.stats.coinsBalance = user!.fut16.coinsBalance
            Log.print("Done?")
        }
    }
    
    @IBAction func totpPushed(sender: NSButton) {
        totpLabel.stringValue = user?.authCode ?? ""
    }
    
    @IBAction func onClick(sender: NSTextField) {
        print("On click")
    }
}
