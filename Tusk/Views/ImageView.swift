//
//  ImageView.swift
//  Tusk
//
//  Created by Patrick Perini on 8/13/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import AlamofireImage

@IBDesignable class ImageView: UIImageView {
    @IBInspectable var round: Bool = false { didSet { self.setNeedsLayout() } }
    
    @IBInspectable var borderWidth: CGFloat = 1.0 { didSet { self.setNeedsLayout() } }
    @IBInspectable var borderColor: UIColor = .clear { didSet { self.setNeedsLayout() } }

    override func layoutSubviews() {
        self.clipsToBounds = self.round
        self.layer.cornerRadius = self.round ? (self.layer.bounds.width / 2.0) : 0
        
        self.layer.borderColor = self.borderColor.cgColor
        self.layer.borderWidth = self.borderWidth
        
        super.layoutIfNeeded()
    }
}
