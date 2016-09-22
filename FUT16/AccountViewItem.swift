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
            print("Setting user \(user.email)")
            usernameLabel.stringValue = user.email
            totpLabel.stringValue = user.authCode
            enabledCheckbox.state = user.enabled ? 1 : 0
            observerContext = user.email
            user.stats.addObserver(self, forKeyPath: "purchaseCount", options: .new, context: &observerContext)
        }
    }
    
    @IBOutlet weak var enabledCheckbox: NSButton!
    @IBOutlet weak var usernameLabel: NSTextField!
    @IBOutlet weak var totpLabel: NSTextField!
    @IBOutlet weak var loginButton: NSButton!
    
    @IBOutlet weak var search1HrLabel: NSTextField!
    @IBOutlet weak var search24HrLabel: NSTextField!
    @IBOutlet weak var purchaseCountLabel: NSTextField!
    
    private var observerContext: String = "context"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setBackground(colorDefault)
    }
    
    override func viewWillAppear() {
        print("Appearing view \(user.email)")
        if user.stats.purchaseCount > 0 {
            setBackground(colorPurchase)
        }
    }
    
    override func viewWillDisappear() {
        print("Removing observer for \(user.email)")
        user.stats.removeObserver(self, forKeyPath: "purchaseCount", context: &observerContext)
    }
    
    override func awakeFromNib() {
        self.view.wantsLayer = true
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &observerContext {
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
