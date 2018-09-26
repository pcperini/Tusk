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
    
    func pinSubview(subview: UIView, to attrs: [NSLayoutAttribute], withSizes sizes: [NSLayoutAttribute: CGFloat], safely: Bool = false) {
        subview.removeConstraints(subview.constraints)        
        self.addConstraints(attrs.map({ NSLayoutConstraint(item: self,
                                                           attribute: safely ? $0.correspondingSafeAttribute : $0,
                                                           relatedBy: .equal,
                                                           toItem: subview,
                                                           attribute: $0,
                                                           multiplier: 1.0,
                                                           constant: 0.0) }))
        subview.addConstraints(sizes.map({ NSLayoutConstraint(item: subview,
                                                              attribute: $0.key,
                                                              relatedBy: .equal,
                                                              toItem: nil,
                                                              attribute: .notAnAttribute,
                                                              multiplier: 1.0,
                                                              constant: $0.value) }))
    }
}

extension NSLayoutAttribute {
    var correspondingSafeAttribute: NSLayoutAttribute {
        switch self {
        case .bottom: return .bottomMargin
        case .top: return .topMargin
        case .centerY: return .centerYWithinMargins
        default: return self
        }
    }
}
