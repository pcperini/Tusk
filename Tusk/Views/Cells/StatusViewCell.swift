//
//  StatusViewCell.swift
//  Tusk
//
//  Created by Patrick Perini on 8/13/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit

class StatusViewCell: UITableViewCell {
    @IBOutlet var avatarView: ImageView!
    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var statusTextView: TextView!
    @IBOutlet var timestampLabel: TimestampLabel!
    @IBOutlet var attachmentCollectionView: UICollectionView!
    
    var avatarWasTapped: (() -> Void)?
    var linkWasTapped: ((URL?) -> Void)?
    
    var status: Status? {
        didSet {
            guard let status = self.status else { return }
            
            self.avatarView.af_setImage(withURL: URL(string: status.account.avatar)!)
            self.displayNameLabel.text = status.account.name
            self.usernameLabel.text = status.account.handle
            self.timestampLabel.date = status.createdAt

            self.statusTextView.htmlText = status.content
            self.statusTextView.setNeedsLayout()
            
//            let activeHeightConstraint = self.attachmentCollectionView.constraints.first {
//                (c) in c.identifier == (status.mediaAttachments.isEmpty ? "CollapsedHeightConstraint" : "ExpandedHeightConstraint")
//            }
//            
//            let inactiveHeightConstraint = self.attachmentCollectionView.constraints.first {
//                (c) in c.identifier == (status.mediaAttachments.isEmpty ? "ExpandedHeightConstraint" : "CollapsedHeightConstraint")
//            }
//            
//            activeHeightConstraint?.priority = .defaultHigh
//            inactiveHeightConstraint?.priority = .defaultLow
//            
//            self.attachmentCollectionView.reloadData()
            
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
     
        self.attachmentCollectionView.register(UINib(nibName: "ImageAttachmentViewCell", bundle: nil), forCellWithReuseIdentifier: "ImageViewCell")
        
        let avatarTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(avatarViewWasTapped(recognizer:)))
        self.avatarView.addGestureRecognizer(avatarTapRecognizer)
        
        self.statusTextView.delegate = self
    }
    
    @objc func avatarViewWasTapped(recognizer: UIGestureRecognizer!) {
        self.avatarWasTapped?()
    }
}

extension StatusViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        self.linkWasTapped?(URL)
        return false
    }
}

extension StatusViewCell: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let status = self.status else { return 0 }
        return status.mediaAttachments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let status = self.status else { return UICollectionViewCell() }
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageViewCell", for: indexPath) as? ImageAttachmentViewCell else { return UICollectionViewCell() }
        
        let attachment = status.mediaAttachments[indexPath.item]
        cell.imageView.af_setImage(withURL: URL(string: attachment.previewURL)!)
        
        return cell
    }
}
