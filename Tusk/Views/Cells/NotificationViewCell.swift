//
//  NotificationViewCell.swift
//  Tusk
//
//  Created by Patrick Perini on 8/14/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit

class NotificationViewCell: TableViewCell {
    private static let actionIconEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    
    @IBOutlet var avatarView: AvatarView!
    @IBOutlet var actionIconView: ImageView!
    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var actionLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var timestampLabel: TimestampLabel!
    
    var avatarWasTapped: (() -> Void)?
    
    private var statusLabelHeight: CGFloat = 0.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.statusLabelHeight = self.statusLabel.bounds.height
        
        let avatarTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(avatarViewWasTapped(recognizer:)))
        self.avatarView.addGestureRecognizer(avatarTapRecognizer)
    }
    
    var notification: MastodonKit.Notification? {
        didSet {
            guard let notification = self.notification else { return }
            
            self.avatarView.avatarURL = URL(string: notification.account.avatar)
            self.avatarView.badgeType = AvatarView.BadgeType(account: notification.account)
            
            self.displayNameLabel.text = notification.account.name
            self.actionLabel.text = notification.action
            self.timestampLabel.date = notification.createdAt
            
            self.setActionIcon(notificationType: notification.type)

            if let status = notification.status {
                self.statusLabel.text = NSAttributedString(htmlString: status.content)?.string
            } else {
                self.statusLabel.text = nil
            }
        }
    }
    
    @objc func avatarViewWasTapped(recognizer: UIGestureRecognizer!) {
        self.avatarWasTapped?()
    }
    
    private func setActionIcon(notificationType: NotificationType) {
        let notificationTypeName = "\(notificationType)".capitalized
        self.actionIconView.backgroundColor = UIColor(named: "\(notificationTypeName)AlertColor")
        self.actionIconView.image = UIImage(named: "\(notificationTypeName)Alert")?.imageWithInsets(insets: NotificationViewCell.actionIconEdgeInsets)
        self.preserveBackgroundColors()
    }
}
