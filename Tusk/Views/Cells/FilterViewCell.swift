//
//  FilterViewCell.swift
//  Tusk
//
//  Created by Patrick Perini on 9/22/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit

class FilterViewCell: TableViewCell {
    @IBOutlet var textView: TextView!
    @IBOutlet var warningSwitch: UISwitch!
    @IBOutlet var regexSwitch: UISwitch!
    
    var filter: Filter! {
        didSet {
            self.textView.text = self.filter.content
            self.warningSwitch.isOn = self.filter.filtersWarnings
            self.regexSwitch.isOn = self.filter.isRegex
        }
    }
    
    
}
