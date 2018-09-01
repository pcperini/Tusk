//
//  FollowViewCell.swift
//  Tusk
//
//  Created by Patrick Perini on 8/22/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit

class FollowViewCell: TableViewCell {
    @IBOutlet var avatarView: AvatarView!
    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var detailLabel: UILabel!
    
    var account: Account! {
        didSet {
            self.avatarView.avatarURL = URL(string: self.account.avatar)
            self.avatarView.badgeType = AvatarView.BadgeType(account: self.account)
            self.displayNameLabel.text = self.account.name
            self.usernameLabel.text = self.account.handle
            self.detailLabel.text = self.account.behaviorTidbit
            self.preserveBackgroundColors()
        }
    }
}

