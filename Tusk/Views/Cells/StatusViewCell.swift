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
    @IBOutlet var timestampLabel: TimestampLabel!
    
    @IBOutlet var warningTextView: TextView!
    @IBOutlet var warningHeightConstraint: NSLayoutConstraint!
    @IBOutlet var warningBottomConstraints: [ToggleLayoutConstraint]!
    
    @IBOutlet var statusTextView: TextView!
    @IBOutlet var statusBottomConstraint: ToggleLayoutConstraint!
    @IBOutlet var statusHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var visibilityBadge: UIImageView!
    @IBOutlet var visibilityWidthConstraints: [ToggleLayoutConstraint]!
    
    @IBOutlet var attachmentCollectionView: UICollectionView!
    @IBOutlet var attachmentBottomConstraint: ToggleLayoutConstraint!
    @IBOutlet var attachmentHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var reblogView: UIView!
    @IBOutlet var reblogAvatarView: ImageView!
    @IBOutlet var reblogLabel: UILabel!
    @IBOutlet var reblogWidthConstraints: [ToggleLayoutConstraint]!
    
    @IBOutlet var reblogStatBadge: UIImageView!
    @IBOutlet var reblogStatLabel: UILabel!
    @IBOutlet var favouriteStatBadge: UIImageView!
    @IBOutlet var favouriteStatLabel: UILabel!
    
    var accountElementWasTapped: ((Account?) -> Void)?
    var linkWasTapped: ((URL?, String) -> Void)?
    var attachmentWasTapped: ((Attachment) -> Void)?
    var contextPushWasTriggered: ((Status?) -> Void)?
    var contentShouldReveal: (() -> Void)?
    
    private var avatarTapRecognizer: UITapGestureRecognizer!
    private var reblogAvatarTapRecognizer: UITapGestureRecognizer!
    private var cellLongPressRecognizer: UILongPressGestureRecognizer!
    
    var originalStatus: Status?
    var status: Status? { didSet { self.updateStatus() } }
    
    var isSupressingContent: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
     
        self.attachmentCollectionView.register(UINib(nibName: "ImageAttachmentViewCell", bundle: nil), forCellWithReuseIdentifier: "ImageViewCell")
        
        self.avatarTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(avatarViewWasTapped(recognizer:)))
        self.avatarView.addGestureRecognizer(self.avatarTapRecognizer)
        
        self.reblogAvatarTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(avatarViewWasTapped(recognizer:)))
        self.reblogView.addGestureRecognizer(self.reblogAvatarTapRecognizer)
        
        self.cellLongPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(cellWasLongPressed(recognizer:)))
        self.addGestureRecognizer(self.cellLongPressRecognizer)
        
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
    
    private func updateStatus(oldValue: Status? = nil) {
        guard let status = self.status else { return }
        
        self.avatarView.avatarURL = URL(string: status.account.avatar)
        self.avatarView.badgeType = AvatarView.BadgeType(account: status.account)
        self.preserveBackgroundColors()
        
        self.displayNameLabel.text = status.account.name
        self.usernameLabel.text = status.account.handle
        self.timestampLabel.date = status.createdAt
        
        switch status.visibility {
        case .private: do {
            self.visibilityBadge.image = UIImage(named: "LockedBadge")
            self.visibilityWidthConstraints.forEach { $0.toggle(on: true) }
            }
        case .direct: do {
            self.visibilityBadge.image = UIImage(named: "MessageBadge")
            self.visibilityWidthConstraints.forEach { $0.toggle(on: true) }
            }
        default: do {
            self.visibilityWidthConstraints.forEach { $0.toggle(on: false) }
            }
        }
        
        self.warningHeightConstraint.priority = status.warning == nil ? .defaultHigh : .init(rawValue: 1)
        self.warningBottomConstraints.forEach { $0.toggle(on: !status.spoilerText.isEmpty) }
        self.warningTextView.htmlText = status.warning
        self.warningTextView.setNeedsLayout()
        
        let hideTextView = status.content.isEmpty || self.isSupressingContent
        self.statusTextView.emojis = status.emojis.map({ ($0.shortcode, $0.url) })
        self.statusTextView.htmlText = hideTextView ? nil : status.content
        self.statusHeightConstraint.priority = hideTextView ? .defaultHigh : .init(rawValue: 1)
        self.statusBottomConstraint.toggle(on: !hideTextView)
        self.statusTextView.setNeedsLayout()
    
        self.attachmentCollectionView.reloadData()
        self.attachmentBottomConstraint.toggle(on: !status.mediaAttachments.isEmpty && !hideTextView)
        self.attachmentHeightConstraint.constant = self.attachmentCollectionView.collectionViewLayout.collectionViewContentSize.height
        self.attachmentCollectionView.setNeedsLayout()
        self.attachmentCollectionView.layoutIfNeeded()
                
        var hasReblogInfo = false
        self.reblogLabel.text = ""
        
        if let originalStatus = self.originalStatus {
            self.reblogAvatarView.af_setImage(withURL: URL(string: originalStatus.account.avatar)!)
            self.reblogLabel.text = originalStatus.account.displayName
            hasReblogInfo = true
        }
        
        self.reblogWidthConstraints.forEach { $0.toggle(on: hasReblogInfo) }
        
        let favourited = status.favourited ?? false
        self.favouriteStatLabel.text = "\(status.favouritesCount)"
        self.favouriteStatBadge.tintColor = UIColor(named: favourited ? "FavouritedBadgeColor" : "StatBadgeColor")
        self.favouriteStatBadge.image = UIImage(named: favourited ? "FavouritedBadge" : "FavouriteBadge")
        
        let reblogged = status.reblogged ?? false
        self.reblogStatLabel.text = "\(status.reblogsCount)"
        self.reblogStatBadge.tintColor = UIColor(named: reblogged ? "RebloggedBadgeColor" : "StatBadgeColor")
        
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
    
    @objc func cellWasLongPressed(recognizer: UIGestureRecognizer!) {
        guard self.isSupressingContent else { return }
        self.contentShouldReveal?()
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
