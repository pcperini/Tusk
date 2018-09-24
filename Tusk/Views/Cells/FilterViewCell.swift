//
//  FilterViewCell.swift
//  Tusk
//
//  Created by Patrick Perini on 9/22/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit
import MGSwipeTableCell

class FilterViewCell: TableViewCell {
    @IBOutlet var textField: UITextField!
    @IBOutlet var warningSwitch: UISwitch!
    @IBOutlet var regexSwitch: UISwitch!
    
    var filterWasUpdated: ((String) -> Void)? = nil
    var filterDeleteWasTriggered: (() -> Void)? = nil
    
    var filter: FilterType! {
        didSet {
            self.textField.text = self.filter.content
            
            self.warningSwitch.isOn = self.filter.filtersWarnings
            self.warningSwitch.isEnabled = self.filter is Filter
            
            self.regexSwitch.isOn = self.filter.isRegex
            self.regexSwitch.isEnabled = self.filter is Filter
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let deleteButton = MGSwipeButton(title: "Delete",
                                         backgroundColor: UIColor(named: "DestructiveButtonColor"),
                                         callback: { (_) in self.filterDeleteWasTriggered?(); return true })
        self.rightButtons = [deleteButton]
        self.rightSwipeSettings.transition = .drag
    }
    
    @IBAction func textFieldValueDidChange(sender: UITextField?) {
        self.filterSettingsWereUpdated()
    }
    
    @IBAction func warningSwitchWasToggled(sender: UISwitch?) {
        self.filterSettingsWereUpdated()
    }
    
    @IBAction func regexSwitchWasToggled(sender: UISwitch?) {
        self.filterSettingsWereUpdated()
    }
    
    private func filterSettingsWereUpdated() {
        let phrase = Filter.phraseForContent(self.textField.text ?? "",
                                             filtersWarnings: self.warningSwitch.isOn,
                                             isRegex: self.regexSwitch.isOn)
        self.filterWasUpdated?(phrase)
    }
}

extension FilterViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
