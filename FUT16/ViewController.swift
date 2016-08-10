//
//  ViewController.swift
//  FUT16
//
//  Created by Kon on 12/15/15.
//  Copyright © 2015 Kon. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var collectionView: NSCollectionView!
    
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
    
    @IBOutlet weak var userFileTextField: NSTextField!
    
    @IBOutlet var logTextView: NSTextView!
    
    var openPanel = NSOpenPanel()
    
    var autoTrader: AutoTrader!
    var users: [FutUser]!

    var aggregateStats = AggregateStats.sharedInstance

    var settings = Settings.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.registerClass(AccountViewItem.self, forItemWithIdentifier: "AccountViewItem")
        
        
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowedFileTypes = ["txt"]
        openPanel.directoryURL = NSURL(fileURLWithPath: NSString(string: "~").stringByExpandingTildeInPath)
//        [_openPanel setAllowsMultipleSelection:NO];
        
        updateFieldsStateForSearchType(typeSegment.selectedLabel())
        updateSettings()
        
        users = UserLoader.getUsers(from: Settings.sharedInstance.userFile)
        
        if users == nil || users.count == 0 {
            selectUsersFile()
        } else {
            autoTrader = AutoTrader(users: users, update: nil)
        }
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
    @IBAction func setSearchParamsPressed(sender: NSButton) {
        let nationality = getIdFromComboBox(nationalityComboBox) ?? ""
        let league = getIdFromComboBox(leagueComboBox) ?? ""
        let team = getIdFromComboBox(teamComboBox) ?? ""
        let level  = getIdFromComboBox(levelComboBox) ?? ""
        
        let minSearchBin = UInt(minBinTextField.stringValue.stringByReplacingOccurrencesOfString(",", withString: "")) ?? 0
        let maxSearchBin = UInt(maxBinTextField.stringValue.stringByReplacingOccurrencesOfString(",", withString: "")) ?? 0
        let buyAtBin = UInt(buyAtTextField.stringValue.stringByReplacingOccurrencesOfString(",", withString: "")) ?? 0
        
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
        var reqTimingMin = reqTimingMinTextField.doubleValue
        let reqTimingMax = reqTimingMaxTextField.doubleValue
        
        // clip min timing to 1.5 seconds
        reqTimingMin = reqTimingMin < 1.5 ? 1.5 : reqTimingMin
        reqTimingMinTextField.doubleValue = reqTimingMin
        
        settings.reqTimingMin = reqTimingMin
        settings.reqTimingMax = reqTimingMax
        settings.cycleTime    = cycleTimeTextField.doubleValue * 60.0       // convert from min to seconds
        settings.cycleBreak   = cycleBreakTextField.doubleValue * 60.0      // convert from min to seconds
        settings.unlockCode   = unlockCodeTextField.stringValue
        settings.userFile     = userFileTextField.stringValue
    }
    
    @IBAction func doStuffPressed(sender: NSButton) {
        setSearchParamsPressed(sender)
        autoTrader?.startTrading()
    }
    
    @IBAction func stopPressed(sender: NSButton) {
        autoTrader?.stopTrading("UI")
    }
    
    @IBAction func resetStatsPressed(sender: NSButton) {
        autoTrader?.resetStats(nil)
        if sender.tag == 99 {
            clearLog()
        }
    }
    
    @IBAction func saveSettingsPressed(sender: NSButton) {
        updateSettings()
        Log.print("Settings: \(settings)")
    }
    
    @IBAction func browsePressed(sender: AnyObject) {
        selectUsersFile()
    }
    
    func selectUsersFile() {
        openPanel.beginWithCompletionHandler { (result) in
            guard result == NSFileHandlingPanelOKButton else { return }
            
            self.userFileTextField.stringValue = self.openPanel.URL!.path!
            NSUserDefaults.standardUserDefaults().setObject(self.userFileTextField.stringValue, forKey: "userFile")
            self.updateSettings()
            self.users = UserLoader.getUsers(from: Settings.sharedInstance.userFile)
            self.collectionView.reloadData()
        }
    }
}

extension ViewController: NSCollectionViewDataSource {
    func collectionView(collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return users?.count ?? 0
    }
    
    func collectionView(collectionView: NSCollectionView, itemForRepresentedObjectAtIndexPath indexPath: NSIndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItemWithIdentifier("AccountViewItem", forIndexPath: indexPath)
        guard let accountItem = item as? AccountViewItem else {
            print("Not account view")
            return item
        }
        
        accountItem.user = users[indexPath.item]
        
        return accountItem
    }
}

extension NSSegmentedControl {
    func selectedLabel() -> String {
        return self.labelForSegment(self.selectedSegment) ?? ""
    }
}

