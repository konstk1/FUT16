//
//  ViewController.swift
//  FUT16
//
//  Created by Kon on 12/15/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Cocoa
import OneTimePassword

class ViewController: NSViewController {

    @IBOutlet weak var email0TextField: NSTextField!
    @IBOutlet weak var password0TextField: NSSecureTextField!
    @IBOutlet weak var secretAnswer0TextField: NSTextField!
    @IBOutlet weak var auth0TextField: NSTextField!
    
    @IBOutlet weak var email1TextField: NSTextField!
    @IBOutlet weak var password1TextField: NSSecureTextField!
    @IBOutlet weak var secretAnswer1TextField: NSTextField!
    @IBOutlet weak var auth1TextField: NSTextField!
    
    @IBOutlet weak var email2TextField: NSTextField!
    @IBOutlet weak var password2TextField: NSSecureTextField!
    @IBOutlet weak var secretAnswer2TextField: NSTextField!
    @IBOutlet weak var auth2TextField: NSTextField!
    
    @IBOutlet weak var email3TextField: NSTextField!
    @IBOutlet weak var password3TextField: NSSecureTextField!
    @IBOutlet weak var secretAnswer3TextField: NSTextField!
    @IBOutlet weak var auth3TextField: NSTextField!
    
    @IBOutlet weak var email4TextField: NSTextField!
    @IBOutlet weak var password4TextField: NSSecureTextField!
    @IBOutlet weak var secretAnswer4TextField: NSTextField!
    @IBOutlet weak var auth4TextField: NSTextField!
    
    @IBOutlet weak var email5TextField: NSTextField!
    @IBOutlet weak var password5TextField: NSSecureTextField!
    @IBOutlet weak var secretAnswer5TextField: NSTextField!
    @IBOutlet weak var auth5TextField: NSTextField!
    
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
    
    var autoTrader: AutoTrader!
    var user0 = FutUser()
    var user1 = FutUser()
    var user2 = FutUser()
    var user3 = FutUser()
    var user4 = FutUser()
    var user5 = FutUser()
    var aggregateStats = AggregateStats.sharedInstance

    var settings = Settings.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        autoTrader = AutoTrader(users: [user0, user1, user2, user3, user4, user5], update: nil)
        
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
    
    func getUserNumbered(num: Int) -> FutUser? {
        switch(num) {
        case 0:
            return user0
        case 1:
            return user1
        case 2:
            return user2
        case 3:
            return user3
        case 4:
            return user4
        case 5:
            return user5
        default:
            return nil
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
        var user: FutUser? = nil
        
        var email = ""
        var password = ""
        var secret = ""
        
        switch accountNum {
        case 0:
            email = email0TextField.stringValue
            password = password0TextField.stringValue
            secret = secretAnswer0TextField.stringValue
            user = user0
        case 1:
            email = email1TextField.stringValue
            password = password1TextField.stringValue
            secret = secretAnswer1TextField.stringValue
            user = user1
        case 2:
            email = email2TextField.stringValue
            password = password2TextField.stringValue
            secret = secretAnswer2TextField.stringValue
            user = user2
        case 3:
            email = email3TextField.stringValue
            password = password3TextField.stringValue
            secret = secretAnswer3TextField.stringValue
            user = user3
        case 4:
            email = email4TextField.stringValue
            password = password4TextField.stringValue
            secret = secretAnswer4TextField.stringValue
            user = user4
        case 5:
            email = email5TextField.stringValue
            password = password5TextField.stringValue
            secret = secretAnswer5TextField.stringValue
            user = user5
        default:
            break
        }
        
        
        user?.email = email
        user?.fut16.login(email, password: password, secretAnswer: secret) {
            user!.stats.coinsBalance = user!.fut16.coinsBalance
        }
        
        Log.print("Logging in [\(sender.tag)] - [\(email)]")
    }
    
    @IBAction func submitPressed(sender: AnyObject) {
        let accountNum = (sender as! NSControl).tag
        var authCode = ""
        var user: FutUser? = nil
        
        switch accountNum {
        case 0:
            authCode = auth0TextField.stringValue
            user = user0
        case 1:
            authCode = auth1TextField.stringValue
            user = user1
        case 2:
            authCode = auth2TextField.stringValue
            user = user2
        case 3:
            authCode = auth3TextField.stringValue
            user = user3
        case 4:
            authCode = auth4TextField.stringValue
            user = user4
        case 5:
            authCode = auth5TextField.stringValue
            user = user5
        default:
            break
        }
        
        let secretData = NSData(base32String: authCode)
        let generator = Generator(factor: .Timer(period: 30), secret: secretData, algorithm: .SHA1, digits: 6)!
        let token = Token(generator: generator)
        
        if let twoFactorCode = token.currentPassword {
            user?.fut16.sendAuthCode(twoFactorCode)
        }
    }
    
    @IBAction func setSearchParamsPressed(sender: NSButton) {
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
    
    @IBAction func updateMaxBin(sender: NSButton) {
        let maxSearchBin = UInt(maxBinTextField.stringValue.stringByReplacingOccurrencesOfString(",", withString: "")) ?? 0
        
        if sender.tag > 0 {
            maxBinTextField.integerValue = Int(incrementPrice(maxSearchBin));
        } else {
            maxBinTextField.integerValue = Int(decrementPrice(maxSearchBin));
        }
        
        setSearchParamsPressed(sender);
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
        autoTrader?.resetStats(getUserNumbered(sender.tag))
        if sender.tag == 99 {
            clearLog()
        }
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

