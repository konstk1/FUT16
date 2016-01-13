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
    @IBOutlet weak var nationalityComboBox: NSComboBox!
    @IBOutlet weak var leagueComboBox: NSComboBox!
    @IBOutlet weak var teamComboBox: NSComboBox!
    @IBOutlet weak var levelComboBox: NSComboBox!
    @IBOutlet weak var binTextField: NSTextField!
    @IBOutlet weak var buyAtTextField: NSTextField!
    @IBOutlet weak var breakEvenTextField: NSTextField!
    
    @IBOutlet weak var loginButton: NSButton!
    @IBOutlet weak var submitButton: NSButton!
    
    private let fut16 = FUT16()
    var autoTrader: AutoTrader!
    dynamic var traderStats = TraderStats()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        autoTrader = AutoTrader(fut16: fut16, update: {
            self.traderStats = self.autoTrader.stats
            //self.traderStats.searchCount = self.autoTrader.stats.searchCount
        })
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func getIdFromComboBox(comboBox: NSComboBox) -> String? {
        if comboBox.stringValue == "Any" {
            return ""
        }
        
        if comboBox == levelComboBox {
            return comboBox.stringValue
        } else {
            // assuming format is "Label: ID"
            let comps = comboBox.stringValue.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: ": "))
            return comps.last
        }
    }

// MARK: UI Actions
    @IBAction func loginPressed(sender: NSButton) {
        fut16.login(emailTextField.stringValue, password: passwordTextField.stringValue, secretAnswer: secretAnswerTextField.stringValue)
    }
    
    @IBAction func submitPressed(sender: NSButton) {
        fut16.sendAuthCode(authTextField.stringValue)
    }
    
    @IBAction func setSearchParamsPressed(sender: NSButton) {
        // Ribery 156616 (43.5k)
        // Neuer 167495 (75k)
        // Martial 211300
        // Tévez 143001
        // Benzema 165153
        // Ramos 155862
        // Alves 146530 (13k)
        let playerId = playerIdTextField.stringValue
        let nationality = getIdFromComboBox(nationalityComboBox) ?? ""
        let league = getIdFromComboBox(leagueComboBox) ?? ""
        let team = getIdFromComboBox(teamComboBox) ?? ""
        let level  = getIdFromComboBox(levelComboBox) ?? ""
        
        let maxSearchBin = UInt(binTextField.integerValue)
        let buyAtBin = UInt(buyAtTextField.integerValue)
 
        let playerParams = FUT16.PlayerParams(playerId: playerId, nationality: nationality, league: league, team: team, level: level,  maxBin: maxSearchBin)
        
        let breakEvenPrice = autoTrader?.setTradeParams(playerParams, buyAtBin: buyAtBin)
        
        breakEvenTextField.integerValue = Int(breakEvenPrice!)
    }
    
    @IBAction func doStuffPressed(sender: NSButton) {
        setSearchParamsPressed(sender)
        autoTrader?.startTrading()
    }
    
    @IBAction func stopPressed(sender: NSButton) {
        autoTrader?.stopTrading("UI")
    }
    
    @IBAction func resetStatsPressed(sender: NSButton) {
        autoTrader?.resetStats()
    }
}

