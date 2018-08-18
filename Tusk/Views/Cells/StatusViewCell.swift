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
    
    private var attachmentCollectionViewTopConstraintConstant: CGFloat = 0.0
    private var attachmentCollectionViewTopConstraint: NSLayoutConstraint? {
        return self.attachmentCollectionView.superview?.constraints.first { (c) in c.identifier == "TopConstraint" }
    }
    private var attachmentCollectionViewHeightConstraint: NSLayoutConstraint? {
        return self.attachmentCollectionView.constraints.first { (c) in c.identifier == "HeightConstraint" }
    }
    
    var accountElementWasTapped: ((Account?) -> Void)?
    var linkWasTapped: ((URL?) -> Void)?
    var attachmentWasTapped: ((Attachment) -> Void)?
    
    var originalStatus: Status?
    var status: Status? { didSet { self.updateStatus() } }
    
    override func awakeFromNib() {
        super.awakeFromNib()
     
        self.attachmentCollectionView.register(UINib(nibName: "ImageAttachmentViewCell", bundle: nil), forCellWithReuseIdentifier: "ImageViewCell")
        
        let avatarTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(avatarViewWasTapped(recognizer:)))
        self.avatarView.addGestureRecognizer(avatarTapRecognizer)
        
        self.statusTextView.delegate = self
        self.attachmentCollectionViewTopConstraintConstant = self.attachmentCollectionViewTopConstraint?.constant ?? 0.0
    }
    
    private func updateStatus() {
        guard let status = self.status else { return }
        
        self.avatarView.af_setImage(withURL: URL(string: status.account.avatar)!)
        self.displayNameLabel.text = status.account.name
        self.usernameLabel.text = status.account.handle
        self.timestampLabel.date = status.createdAt
        
        self.statusTextView.htmlText = status.content
        self.statusTextView.setNeedsLayout()
    
        self.attachmentCollectionViewTopConstraint?.constant = status.mediaAttachments.isEmpty ? 0 : self.attachmentCollectionViewTopConstraintConstant
        self.attachmentCollectionView.reloadData()
        self.attachmentCollectionViewHeightConstraint?.constant = self.attachmentCollectionView.collectionViewLayout.collectionViewContentSize.height
        self.attachmentCollectionView.setNeedsLayout()
        self.attachmentCollectionView.layoutIfNeeded()
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    @objc func avatarViewWasTapped(recognizer: UIGestureRecognizer!) {
        self.accountElementWasTapped?(self.status?.account)
    }
}

extension StatusViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        self.linkWasTapped?(URL)
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
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageViewCell", for: indexPath) as? ImageAttachmentViewCell else { return UICollectionViewCell() }
        
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
