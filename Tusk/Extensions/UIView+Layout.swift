//
//  UIView+Layout.swift
//  Tusk
//
//  Created by Patrick Perini on 8/23/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

extension UIView {
    func constraints(pinning attributes: [NSLayoutAttribute], to view: UIView) -> [NSLayoutConstraint] {
        return attributes.map({ (attribute) in
            return NSLayoutConstraint(item: self,
                                      attribute: attribute,
                                      relatedBy: .equal,
                                      toItem: view,
                                      attribute: attribute,
                                      multiplier: 1.0,
                                      constant: 0.0)
        })
    }
    
    func constraints(pinning attributes: [NSLayoutAttribute: CGFloat], to view: UIView) -> [NSLayoutConstraint] {
        return attributes.map({ (attribute, constant) in
            return NSLayoutConstraint(item: self,
                                      attribute: attribute,
                                      relatedBy: .equal,
                                      toItem: view,
                                      attribute: attribute,
                                      multiplier: 1.0,
                                      constant: constant)
        })
    }
    
    func ratioConstraints(pinning attributes: [NSLayoutAttribute: CGFloat], to view: UIView) -> [NSLayoutConstraint] {
        return attributes.map({ (attribute, multipler) in
            return NSLayoutConstraint(item: self,
                                      attribute: attribute,
                                      relatedBy: .equal,
                                      toItem: view,
                                      attribute: attribute,
                                      multiplier: 1.0 / multipler,
                                      constant: 0.0)
        })
    }
    
    func constantConstraints(setting attributes: [NSLayoutAttribute: CGFloat]) -> [NSLayoutConstraint] {
        return attributes.map({ (attribute, constant) in
            return NSLayoutConstraint(item: self,
                                      attribute: attribute,
                                      relatedBy: .equal,
                                      toItem: nil,
                                      attribute: .notAnAttribute,
                                      multiplier: 1.0,
                                      constant: constant)
        })
    }
    
    func constraintsAffectingAttribute(attribute: NSLayoutAttribute) -> [NSLayoutConstraint] {
        return self.constraints.filter({ (constraint) in
            constraint.firstAttribute == attribute
        })
    }
}
