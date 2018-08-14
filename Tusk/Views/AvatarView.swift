//
//  AvatarView.swift
//  Tusk
//
//  Created by Patrick Perini on 8/13/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import AlamofireImage

@IBDesignable class AvatarView: UIImageView {
    @IBInspectable var round: Bool = false {
        didSet {
            self.clipsToBounds = self.round
            if (self.round != oldValue) {
                self.setNeedsLayout()
            }
        }
    }
    
    @IBInspectable var borderColor: UIColor = .clear {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        self.layer.cornerRadius = self.round ? (self.layer.bounds.width / 2.0) : 0
        self.layer.borderColor = self.borderColor.cgColor
        self.layer.borderWidth = 1.0
        super.layoutIfNeeded()
    }
}
