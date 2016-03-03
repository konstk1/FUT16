//
//  ViewController.swift
//  FUT16
//
//  Created by Kon on 12/15/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var email0TextField: NSTextField!
    @IBOutlet weak var password0TextField: NSSecureTextField!
    @IBOutlet weak var secretAnswer0TextField: NSTextField!
    @IBOutlet weak var auth0TextField: NSTextField!
    
    @IBOutlet weak var email1TextField: NSTextField!
    @IBOutlet weak var password1TextField: NSSecureTextField!
    @IBOutlet weak var secretAnswer1TextField: NSTextField!
    @IBOutlet weak var auth1TextField: NSTextField!
    
    @IBOutlet weak var typeSegment: NSSegmentedControl!
    
    @IBOutlet weak var playerIdTextField: NSTextField!
    @IBOutlet weak var nationalityComboBox: NSComboBox!
    @IBOutlet weak var leagueComboBox: NSComboBox!
    @IBOutlet weak var teamComboBox: NSComboBox!
    @IBOutlet weak var levelComboBox: NSComboBox!
    @IBOutlet weak var minBinTextField: NSTextField!
    @IBOutlet weak var maxBinTextField: NSTextField!
    @IBOutlet weak var buyAtTextField: NSTextField!
    @IBOutlet weak var breakEvenTextField: NSTextField!
    
    // Settings outlets
    @IBOutlet weak var reqTimingMinTextField: NSTextField!
    @IBOutlet weak var reqTimingMaxTextField: NSTextField!
    @IBOutlet weak var cycleTimeTextField: NSTextField!
    @IBOutlet weak var cycleBreakTextField: NSTextField!
    @IBOutlet weak var unlockCodeTextField: NSTextField!
    
    @IBOutlet var logTextView: NSTextView!
    
    private var fut16 = [FUT16]()
    var autoTrader: AutoTrader!
    dynamic var traderStats = TraderStats()
    var settings = Settings.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add two places for now
        fut16.append(FUT16())
        fut16.append(FUT16())
        
        updateFieldsStateForSearchType(typeSegment.selectedLabel())
        updateSettings()
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
    
    func log(string: String) {
        logTextView.textStorage?.appendAttributedString(NSAttributedString(string: string, attributes: [NSFontAttributeName : NSFont(name: "Menlo", size: 11)!]))
        logTextView.scrollToEndOfDocument(nil)
    }
    
    func clearLog() {
        logTextView.string = ""
    }

// MARK: UI Actions
    @IBAction func loginPressed(sender: NSButton) {
        let accountNum = sender.tag
        
        var email = ""
        var password = ""
        var secret = ""
        
        switch accountNum {
        case 0:
            email = email0TextField.stringValue
            password = password0TextField.stringValue
            secret = secretAnswer0TextField.stringValue
        case 1:
            email = email1TextField.stringValue
            password = password1TextField.stringValue
            secret = secretAnswer1TextField.stringValue
        default:
            break
        }
        
        fut16[accountNum].login(email, password: password, secretAnswer: secret)
        Log.print("Logging in [\(sender.tag)] - [\(email)]")
//
//        if autoTrader != nil {
//            autoTrader.stopAllTimers()
//        }
//        
//        autoTrader = AutoTrader(fut16: fut16, update: {
//            self.traderStats = self.autoTrader.stats
//        })
    }
    
    @IBAction func submitPressed(sender: NSButton) {
        let accountNum = sender.tag
        var authCode = ""
        
        switch accountNum {
        case 0:
            authCode = auth0TextField.stringValue
        case 1:
            authCode = auth1TextField.stringValue
        default:
            break
        }
        
        fut16[accountNum].sendAuthCode(authCode)
    }
    
    @IBAction func setSearchParamsPressed(sender: NSButton) {
        // Ribery 156616 (43.5k)
        // Neuer 167495 (105k)
        // Tévez 143001
        // Benzema 165153
        // Ramos 155862
        // Alves 146530 (13k)
        // Alaba 197445 (40k)
        
        let nationality = getIdFromComboBox(nationalityComboBox) ?? ""
        let league = getIdFromComboBox(leagueComboBox) ?? ""
        let team = getIdFromComboBox(teamComboBox) ?? ""
        let level  = getIdFromComboBox(levelComboBox) ?? ""
        
        let minSearchBin = UInt(minBinTextField.integerValue)
        let maxSearchBin = UInt(maxBinTextField.integerValue)
        let buyAtBin = UInt(buyAtTextField.integerValue)
        
        var params: FUT16.ItemParams!
        
        switch typeSegment.selectedLabel() {
        case "Player":
            let playerId = playerIdTextField.stringValue
            params = FUT16.PlayerParams(playerId: playerId, nationality: nationality, league: league, team: team, level: level, minBin: minSearchBin, maxBin: maxSearchBin)
        case "Fitness":
            params = FUT16.ConsumableParams(category: "fitness", level: level, minBin: minSearchBin, maxBin: maxSearchBin)
        case "Manager":
            break
        default:
            break
        }
        
        let breakEvenPrice = autoTrader?.setTradeParams(params, buyAtBin: buyAtBin)
        breakEvenTextField.integerValue = Int(breakEvenPrice!)
    }
    
    @IBAction func typeSegmentChanged(sender: NSSegmentedControl) {
        updateFieldsStateForSearchType(sender.selectedLabel())
    }
    
    func updateFieldsStateForSearchType(type: String) {
        // enable all and then disabled necessary fields based on type
        playerIdTextField.enabled = true
        playerIdTextField.enabled = true
        teamComboBox.enabled = true
        leagueComboBox.enabled = true
        nationalityComboBox.enabled = true
        
        switch type {
        case "Player":
            break
        case "Fitness":
            playerIdTextField.enabled = false
            teamComboBox.enabled = false
            leagueComboBox.enabled = false
            nationalityComboBox.enabled = false
        case "Manager":
            playerIdTextField.enabled = false
        default:
            break
        }
    }
    
    func updateSettings() {
        settings.reqTimingMin = reqTimingMinTextField.doubleValue
        settings.reqTimingMax = reqTimingMaxTextField.doubleValue
        settings.cycleTime    = cycleTimeTextField.doubleValue * 60.0       // convert from min to seconds
        settings.cycleBreak   = cycleBreakTextField.doubleValue * 60.0      // convert from min to seconds
        settings.unlockCode   = unlockCodeTextField.stringValue
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
        clearLog()
    }
    
    @IBAction func saveSettingsPressed(sender: NSButton) {
        updateSettings()
        Log.print("Settings: \(settings)")
    }
}

extension NSSegmentedControl {
    func selectedLabel() -> String {
        return self.labelForSegment(self.selectedSegment) ?? ""
    }
}

