//
//  NotificationViewCell.swift
//  Tusk
//
//  Created by Patrick Perini on 8/14/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit

class NotificationViewCell: UITableViewCell {
    @IBOutlet var avatarView: ImageView!
    @IBOutlet var actionIconView: ImageView!
    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var actionLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    
    private var statusLabelHeight: CGFloat = 0.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.statusLabelHeight = self.statusLabel.bounds.height
    }
    
    var notification: MastodonKit.Notification? {
        didSet {
            guard let notification = self.notification else { return }
            
            self.avatarView.af_setImage(withURL: URL(string: notification.account.avatar)!)
            self.displayNameLabel.text = notification.account.name
            self.actionLabel.text = notification.action
            
            let heightConstraint = self.statusLabel.constraints.filter({ (constraint) in constraint.identifier == "HeightConstraint" }).first
            if let status = notification.status {
                self.statusLabel.text = status.plainContent
                heightConstraint?.constant = self.statusLabelHeight
            } else {
                heightConstraint?.constant = 0
            }
        }
    }
}
