//
//  ImageAttachmentViewCell.swift
//  Tusk
//
//  Created by Patrick Perini on 8/17/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

class ImageAttachmentViewCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    
    var cellWasLongPressed: (() -> Void)? = nil
    private var longPressRecognizer: UILongPressGestureRecognizer!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressWasRecognized(sender:)))
        self.addGestureRecognizer(self.longPressRecognizer)
    }
    
    @objc func longPressWasRecognized(sender: UIGestureRecognizer?) {
        self.cellWasLongPressed?()
    }
}
