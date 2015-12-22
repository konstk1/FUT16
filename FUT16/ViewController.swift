//
//  ViewController.swift
//  FUT16
//
//  Created by Konstantin Klitenik on 12/15/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var emailTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var authTextField: NSTextField!
    
    @IBOutlet weak var secretAnswerTextField: NSTextField!
    
    @IBOutlet weak var playerIdTextField: NSTextField!
    @IBOutlet weak var binTextField: NSTextField!
    @IBOutlet weak var buyAtTextField: NSTextField!
    @IBOutlet weak var breakEvenTextField: NSTextField!
    
    @IBOutlet weak var loginButton: NSButton!
    @IBOutlet weak var submitButton: NSButton!
    
    private let fut16 = FUT16()
    private var autoTrader: AutoTrader!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        loadSavedSettings()
        autoTrader = AutoTrader(fut16: fut16)
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func loginPressed(sender: NSButton) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(emailTextField.stringValue, forKey: "ea-email")
        defaults.setValue(passwordTextField.stringValue, forKey: "ea-password")
        defaults.setValue(secretAnswerTextField.stringValue, forKey: "ea-secret")
        
        fut16.login(emailTextField.stringValue, password: passwordTextField.stringValue, secretAnswer: secretAnswerTextField.stringValue)
    }
    
    @IBAction func submitPressed(sender: NSButton) {
        fut16.sendAuthCode(authTextField.stringValue)
    }
    
    @IBAction func setSearchParamsPressed(sender: NSButton) {
        // Ribery 156616
        // Neuer 167495
        // Götze 192318
        // Martial 211300
        let playerId = playerIdTextField.stringValue
        let maxSearchBin = UInt(binTextField.integerValue)
        let buyAtBin = UInt(buyAtTextField.integerValue)
 
        let breakEvenPrice = autoTrader?.setTradeParams(playerId, maxSearchBin: maxSearchBin, buyAtBin: buyAtBin)
        
        breakEvenTextField.integerValue = Int(breakEvenPrice!)
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(playerIdTextField.stringValue, forKey: "ea-player-id")
        defaults.setValue(binTextField.stringValue, forKey: "ea-max-search-bin")
        defaults.setValue(buyAtTextField.stringValue, forKey: "ea-buy-at-bin")
    }
    
    @IBAction func doStuffPressed(sender: NSButton) {
        setSearchParamsPressed(sender)
        autoTrader?.startTrading()
    }
    
    private func loadSavedSettings() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let email = defaults.valueForKey("ea-email") as? String {
            emailTextField.stringValue = email
        }
        if let pass = defaults.valueForKey("ea-password") as? String {
            passwordTextField.stringValue = pass
        }
        if let secret = defaults.valueForKey("ea-secret") as? String {
            secretAnswerTextField.stringValue = secret
        }
        if let playerId = defaults.valueForKey("ea-player-id") as? String {
            playerIdTextField.stringValue = playerId
        }
        if let maxSearchBin = defaults.valueForKey("ea-max-search-bin") as? String {
            binTextField.stringValue = String(maxSearchBin)
        }
        if let buyAtBin = defaults.valueForKey("ea-buy-at-bin") as? String {
            buyAtTextField.stringValue = String(buyAtBin)
        }
    }
}

