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
            passwordTextField.stringValue = user?.password ?? ""
            answerTextField.stringValue = user?.answer ?? ""
            totpToken.stringValue = user?.totpToken ?? ""
        }
    }
    
    @IBOutlet weak var usernameLabel: NSTextField!
    @IBOutlet weak var passwordTextField: NSTextField!
    @IBOutlet weak var answerTextField: NSTextField!
    @IBOutlet weak var totpToken: NSTextField!
    @IBOutlet weak var loginButton: NSButton!
    
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
}
