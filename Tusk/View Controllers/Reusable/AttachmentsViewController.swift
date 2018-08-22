//
//  AttachmentsViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/18/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Lightbox
import MastodonKit

class AttachmentsViewController: LightboxController {
    static func configure() {
        LightboxConfig.CloseButton.enabled = false
    }
    
    convenience init(attachments: [Attachment], initialAttachment: Attachment?) {
        let images = attachments.compactMap { (attachment) -> LightboxImage? in
            switch attachment.type {
            case .image: return LightboxImage(imageURL: URL(string: attachment.url)!, text: "", videoURL: nil)
            case .gifv, .video: return LightboxImage(imageURL: URL(string: attachment.previewURL)!, text: "", videoURL: URL(string: attachment.url)!)
            default: return nil
            }
        }
        
        let startIndex = (initialAttachment != nil ? attachments.index(of: initialAttachment!) : 0) ?? 0
        self.init(images: images, startIndex: startIndex)
    }
    
    override init(images: [LightboxImage], startIndex index: Int) {
        super.init(images: images, startIndex: index)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
