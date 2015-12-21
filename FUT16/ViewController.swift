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
    
    @IBOutlet weak var loginButton: NSButton!
    @IBOutlet weak var submitButton: NSButton!
    
    private let fut16 = FUT16()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        loadSavedSettings()
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
    
    @IBAction func doStuffPressed(sender: NSButton) {
        findMinBin()
        NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("findMinBin"), userInfo: nil, repeats: true)
    }
    
    var minPrice: UInt = 150
    var minBin: UInt = 1000000
    var numSearches = 0
    
    
    
    func findMinBin() {
        // Ribery 156616
        // Neuer 167495
        // Götze 192318
        var curMinBin: UInt = 1000000
        
        fut16.findBinForPlayerId("192318", maxBin: 5500) { (auctions) -> Void in
            auctions.forEach({ (id, bin) -> () in
                if let curBin = UInt(bin) {
                    if curBin < curMinBin {
                        curMinBin = curBin
                    }
                }
            })
            
            if curMinBin < self.minBin {
                self.minBin = curMinBin
            }
            
            self.numSearches++
            print("Search: \(self.numSearches) - Cur Min: \(curMinBin) (Min: \(self.minBin))")
        }
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
    }
}

