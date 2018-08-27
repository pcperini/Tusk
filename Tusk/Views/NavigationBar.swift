//
//  NavigationBar.swift
//  Tusk
//
//  Created by Patrick Perini on 8/26/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

@IBDesignable class NavigationBar: UINavigationBar {
    @IBInspectable var isShadowHidden: Bool = true
    private static let fullShadowRadius: CGFloat = 3.0
    private static let fullShadowOpacity: Float = 0.7
    
    override func awakeFromNib() {
        self.layer.shadowColor = self.tintColor.cgColor
        self.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        self.layer.shadowRadius = self.isShadowHidden ? 0.0 : NavigationBar.fullShadowRadius
        self.layer.shadowOpacity = self.isShadowHidden ? 0.0 : NavigationBar.fullShadowOpacity
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.shadowRadius = self.isShadowHidden ? 0.0 : NavigationBar.fullShadowRadius
        self.layer.shadowOpacity = self.isShadowHidden ? 0.0 : NavigationBar.fullShadowOpacity
    }
    
    func setShadowHidden(hidden: Bool, animated: Bool) {
        self.isShadowHidden = hidden
        
        defer { self.setNeedsLayout() }
        guard animated else { return }
        
        let radiusValue: CGFloat = self.isShadowHidden ? 0.0 : NavigationBar.fullShadowRadius
        let opacityValue: Float = self.isShadowHidden ? 0.0 : NavigationBar.fullShadowOpacity

        [("shadowOpacity", opacityValue), ("shadowRadius", radiusValue)].forEach { (newValue: (String, Any)) in
            let animation = CABasicAnimation(keyPath: newValue.0)
            animation.fromValue = self.layer.value(forKeyPath: newValue.0) as! CGFloat
            animation.toValue = newValue.1
            animation.duration = 0.2
            
            self.layer.add(animation, forKey: newValue.0)
        }

        self.layer.shadowRadius = radiusValue
        self.layer.shadowOpacity = opacityValue

    }
}
