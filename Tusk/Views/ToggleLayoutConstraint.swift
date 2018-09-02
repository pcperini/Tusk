//
//  ToggleLayoutConstraint.swift
//  Tusk
//
//  Created by Patrick Perini on 8/18/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

@IBDesignable class ToggleLayoutConstraint: NSLayoutConstraint {
    var targetConstant: CGFloat = 0.0
    @IBInspectable var isToggledOn: Bool = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if (self.targetConstant == 0.0 && self.constant != 0.0) {
            self.targetConstant = self.constant
        }
    }
    
    func toggle(on: Bool? = nil) {
        self.isToggledOn = on ?? !self.isToggledOn
        self.constant = self.isToggledOn ? self.targetConstant : 0
    }
}
