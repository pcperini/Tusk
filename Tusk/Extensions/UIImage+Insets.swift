//
//  UIImage+Insets.swift
//  Tusk
//
//  Created by Patrick Perini on 8/16/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

extension UIImage {
    func imageWithInsets(insets: UIEdgeInsets) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: self.size.width + insets.left + insets.right,
                   height: self.size.height + insets.top + insets.bottom), false, self.scale)
        let _ = UIGraphicsGetCurrentContext()
        let origin = CGPoint(x: insets.left, y: insets.top)
        self.draw(at: origin)
        let imageWithInsets = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageWithInsets?.withRenderingMode(self.renderingMode)
    }
}
