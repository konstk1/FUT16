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
let colorDefault = NSColor.white

class AccountViewItem: NSCollectionViewItem {
    
    dynamic var user: FutUser! {
        didSet {
            guard isViewLoaded else { return }
            usernameLabel.stringValue = user.email
            totpLabel.stringValue = user.authCode
            user.enabled = (enabledCheckbox.state == 1)
        }
    }
    
    @IBOutlet weak var enabledCheckbox: NSButton!
    @IBOutlet weak var usernameLabel: NSTextField!
    @IBOutlet weak var totpLabel: NSTextField!
    @IBOutlet weak var loginButton: NSButton!
    
    @IBOutlet weak var search1HrLabel: NSTextField!
    @IBOutlet weak var search24HrLabel: NSTextField!
    @IBOutlet weak var purchaseCountLabel: NSTextField!
    
    fileprivate var myContext = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setBackground(colorDefault)
    }
    
    deinit {
        print("Removing observer")
        user.stats.removeObserver(self, forKeyPath: "purchaseCount", context: &myContext)
    }
    
    override func awakeFromNib() {
        self.view.wantsLayer = true
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &myContext {
            print("Observed new val \(change)")
            if let purchaseCount = change?[NSKeyValueChangeKey.newKey] as? Int {
                print("New purchase count: \(purchaseCount)")
                if purchaseCount > 0 {
                    setBackground(colorPurchase)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    @IBAction func enabledPushed(_ sender: NSButton) {
        user.enabled = (sender.state == 1)
    }
    
    func setBackground(_ color: NSColor) {
        self.view.layer?.backgroundColor = color.cgColor
    }
    
    @IBAction func loginPushed(_ sender: NSButton) {
        Log.print("Login: \(user.username)")
        self.setBackground(colorLoggingIn)
        user.fut16.login(user.email, password: user.password, secretAnswer: user.answer) {
            self.user.stats.coinsBalance = self.user.fut16.coinsBalance
            self.setBackground(colorLoggedIn)
        }
        user.stats.addObserver(self, forKeyPath: "purchaseCount", options: .new, context: &myContext)
    }
    
    @IBAction func totpPushed(_ sender: NSButton) {
        totpLabel.stringValue = user.authCode
        user.fut16.sendAuthCode(user.authCode)
    }
    
    var i = 0
    
    @IBAction func resetPushed(_ sender: NSButton) {
        user.resetStats()
        setBackground(colorDefault)
        totpLabel.stringValue = user.authCode
    }
}
