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
        
        fut16.login(emailTextField.stringValue, password: passwordTextField.stringValue)
    }
    
    @IBAction func submitPressed(sender: NSButton) {
        fut16.sendAuthCode(authTextField.stringValue)
    }
    
    private func loadSavedSettings() {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let email = defaults.valueForKey("ea-email") as? String {
            emailTextField.stringValue = email
        }
        if let pass = defaults.valueForKey("ea-password") as? String {
            passwordTextField.stringValue = pass
        }
    }
}

