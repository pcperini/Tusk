//
//  View.swift
//  Tusk
//
//  Created by Patrick Perini on 9/12/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

@IBDesignable class View: UIView {
    @IBInspectable var borderWidth: CGFloat = 1.0 { didSet { self.setNeedsLayout() } }
    @IBInspectable var borderColor: UIColor = .clear { didSet { self.setNeedsLayout() } }
    @IBInspectable var cornerRadius: CGFloat = 0.0 { didSet { self.setNeedsLayout() } }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.borderWidth = self.borderWidth
        self.layer.borderColor = self.borderColor.cgColor
        self.layer.cornerRadius = self.cornerRadius
    }
}
