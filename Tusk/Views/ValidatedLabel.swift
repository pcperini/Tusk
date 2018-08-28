//
//  ValidatedLabel.swift
//  Tusk
//
//  Created by Patrick Perini on 8/28/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

@IBDesignable class ValidatedLabel: UILabel {
    enum Validity {
        case Valid
        case Warn
        case Invalid
    }
    
    @IBInspectable var validColor: UIColor = .darkText { didSet { self.setNeedsLayout() } }
    @IBInspectable var warnColor: UIColor = .yellow { didSet { self.setNeedsLayout() } }
    @IBInspectable var invalidColor: UIColor = .red { didSet { self.setNeedsLayout() } }
    
    var validity: Validity = .Valid { didSet { self.setNeedsLayout() } }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        switch self.validity {
        case .Valid: self.textColor = self.validColor
        case .Warn: self.textColor = self.warnColor
        case .Invalid: self.textColor = self.invalidColor
        }
    }
}
