//
//  ModalHandlers.swift
//  Tusk
//
//  Created by Patrick Perini on 9/26/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import SafariServices
import MastodonKit

struct ModalHandler {
    static func handleLinkForViewController(viewController: UIViewController) -> (URL?, String) -> Void {
        return { (url: URL?, text: String) in
            guard let url = url else { return }
            let safari = SFSafariViewController(url: url)
            viewController.present(safari, animated: true, completion: nil)
        }
    }
    
    static func handleAttachmentForViewController(viewController: UIViewController, status: Status) -> (Attachment) -> Void {
        return { (attachment: Attachment) in
            let photoViewer = AttachmentsViewController(attachments: status.mediaAttachments, initialAttachment: attachment)
            viewController.present(photoViewer, animated: true, completion: nil)
        }
    }
}
