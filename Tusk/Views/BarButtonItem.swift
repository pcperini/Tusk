//
//  BarButtonItem.swift
//  Tusk
//
//  Created by Patrick Perini on 8/28/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

@IBDesignable class BarButtonItem: UIBarButtonItem {
    @IBInspectable var bold: Bool = false { didSet { self.updateFont() } }
    @IBInspectable var light: Bool = false { didSet { self.updateFont() } }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.updateFont()
    }
    
    private func updateFont() {
        let value = self.titleTextAttributes(for: .normal)?[NSAttributedStringKey.font.rawValue]
        var font = (value as? UIFont) ?? UIFont.systemFont(ofSize: UIFont.buttonFontSize)
        
        if self.bold {
            font = UIFont.systemFont(ofSize: font.pointSize, weight: .bold)
        } else if self.light {
            font = UIFont.systemFont(ofSize: font.pointSize, weight: .light)
        }
        
        self.setTitleTextAttributes([.font: font], for: .normal)
    }
}
