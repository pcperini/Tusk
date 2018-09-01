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
    
    func jpeg(maxSize: Int = Int.max, compression: CGFloat = 0.0, maxDimensions: CGSize = CGRect.infinite.size) -> Data? {
        let oversized = self.size.width > maxDimensions.width || self.size.height > maxDimensions.height
        let img = oversized ? self.imageAspectScaled(toFit: maxDimensions) : self
        
        guard let data = UIImageJPEGRepresentation(img, compression) else { return nil }
        if data.count > maxSize {
            return img.jpeg(maxSize: maxSize, compression: compression + 0.1, maxDimensions: maxDimensions)
        }
        
        return data
    }
    
    public func imageAspectScaled(toFit size: CGSize) -> UIImage {
        assert(size.width > 0 && size.height > 0, "You cannot safely scale an image to a zero width or height")
        
        let imageAspectRatio = self.size.width / self.size.height
        let canvasAspectRatio = size.width / size.height
        
        var resizeFactor: CGFloat
        
        if imageAspectRatio > canvasAspectRatio {
            resizeFactor = size.width / self.size.width
        } else {
            resizeFactor = size.height / self.size.height
        }
        
        let scaledSize = CGSize(width: self.size.width * resizeFactor, height: self.size.height * resizeFactor)
        
        UIGraphicsBeginImageContextWithOptions(scaledSize, false, 0.0)
        draw(in: CGRect(origin: .zero, size: scaledSize))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
}
