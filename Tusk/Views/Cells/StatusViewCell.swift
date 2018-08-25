//
//  StatusViewCell.swift
//  Tusk
//
//  Created by Patrick Perini on 8/13/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit
import MGSwipeTableCell

class StatusViewCell: TableViewCell {
    @IBOutlet var avatarView: AvatarView!
    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var statusTextView: TextView!
    @IBOutlet var timestampLabel: TimestampLabel!
    
    @IBOutlet var attachmentCollectionView: UICollectionView!
    @IBOutlet var attachmentTopConstraint: ToggleLayoutConstraint!
    @IBOutlet var attachmentHeightConstraint: ToggleLayoutConstraint!
    
    @IBOutlet var reblogView: UIView!
    @IBOutlet var reblogIndicatorView: ImageView!
    @IBOutlet var reblogAvatarView: ImageView!
    @IBOutlet var reblogLabel: UILabel!
    @IBOutlet var reblogTopConstraint: ToggleLayoutConstraint!
    @IBOutlet var reblogHeightConstraint: ToggleLayoutConstraint!
    
    private static let reblogIconEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    
    var accountElementWasTapped: ((Account?) -> Void)?
    var linkWasTapped: ((URL?, String) -> Void)?
    var attachmentWasTapped: ((Attachment) -> Void)?
    var contextPushWasTriggered: ((Status?) -> Void)?
    
    private var avatarTapRecognizer: UITapGestureRecognizer!
    private var reblogAvatarTapRecognizer: UITapGestureRecognizer!
    
    var originalStatus: Status?
    var status: Status? { didSet { self.updateStatus() } }
    
    override func awakeFromNib() {
        super.awakeFromNib()
     
        self.attachmentCollectionView.register(UINib(nibName: "ImageAttachmentViewCell", bundle: nil), forCellWithReuseIdentifier: "ImageViewCell")
        
        self.avatarTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(avatarViewWasTapped(recognizer:)))
        self.avatarView.addGestureRecognizer(self.avatarTapRecognizer)
        
        self.reblogAvatarTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(avatarViewWasTapped(recognizer:)))
        self.reblogView.addGestureRecognizer(self.reblogAvatarTapRecognizer)
        self.reblogIndicatorView.image = self.reblogIndicatorView.image?.imageWithInsets(insets: StatusViewCell.reblogIconEdgeInsets)
        
        self.statusTextView.delegate = self
        self.statusTextView.hideLinkCriteria = { (link) in
            guard let status = self.status else { return false }
            return status.allMediaAttachmentURLs.contains(link)
        }
        
        let contextButton = MGSwipeButton(title: "",
                                          icon: UIImage(named: "ContextButton"),
                                          backgroundColor: UIColor(named: "ContextBackgroundColor"),
                                          padding: Int(self.frame.width / 8.0),
                                          callback: { (_) in self.contextPushWasTriggered?(self.status); return false })
        contextButton.tintColor = .lightGray
        self.rightButtons = [contextButton]
        self.rightExpansion.buttonIndex = 0
        self.rightExpansion.fillOnTrigger = true
        self.rightExpansion.threshold = 0.3
        self.rightSwipeSettings.transition = .drag
    }
    
    private func updateStatus() {
        guard let status = self.status else { return }
        
        self.avatarView.avatarURL = URL(string: status.account.avatar)
        self.avatarView.badgeType = AvatarView.BadgeType(account: status.account)
        self.preserveBackgroundColors()
        
        self.displayNameLabel.text = status.account.name
        self.usernameLabel.text = status.account.handle
        self.timestampLabel.date = status.createdAt
        
        self.statusTextView.htmlText = status.content
        self.statusTextView.setNeedsLayout()
    
        self.attachmentTopConstraint.toggle(on: !status.mediaAttachments.isEmpty)
        self.attachmentCollectionView.reloadData()
        self.attachmentHeightConstraint.constant = self.attachmentCollectionView.collectionViewLayout.collectionViewContentSize.height
        self.attachmentCollectionView.setNeedsLayout()
        self.attachmentCollectionView.layoutIfNeeded()
        
        if let originalStatus = self.originalStatus {
            self.reblogAvatarView.af_setImage(withURL: URL(string: originalStatus.account.avatar)!)
            self.reblogLabel.text = originalStatus.account.displayName
        }
        
        self.reblogTopConstraint.toggle(on: self.originalStatus != status && self.originalStatus != nil)
        self.reblogHeightConstraint.toggle(on: self.originalStatus != status && self.originalStatus != nil)
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    @objc func avatarViewWasTapped(recognizer: UIGestureRecognizer!) {
        switch recognizer {
        case self.avatarTapRecognizer: self.accountElementWasTapped?(self.status?.account)
        case self.reblogAvatarTapRecognizer: self.accountElementWasTapped?(self.originalStatus?.account)
        default: return
        }
    }
}

extension StatusViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let substring = textView.attributedText.attributedSubstring(from: characterRange).string
        self.linkWasTapped?(URL, substring)
        return false
    }
}

extension StatusViewCell: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let status = self.status else { return 0 }
        return status.mediaAttachments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let status = self.status else { return UICollectionViewCell() }
        let cell: ImageAttachmentViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageViewCell",
                                                                               for: indexPath,
                                                                               usingNibNamed: "ImageAttachmentViewCell")
        
        let attachment = status.mediaAttachments[indexPath.item]
        cell.imageView.af_setImage(withURL: URL(string: attachment.previewURL)!)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
        guard let status = self.status else { return layout.itemSize }

        var size = CGSize(width: 0, height: collectionView.bounds.width / 2)
        if (indexPath.row < status.mediaAttachments.count - 1) {
            size.width = size.height
        } else { // Last element
            if (status.mediaAttachments.count % 2 == 0) { // Even
                size.width = size.height
            } else { // Odd
                size.width = collectionView.bounds.width
            }
        }
        
        size.width -= layout.minimumInteritemSpacing
        size.height -= layout.minimumInteritemSpacing
        
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let attachment = self.status?.mediaAttachments[indexPath.row] else { return }
        self.attachmentWasTapped?(attachment)
    }
}
