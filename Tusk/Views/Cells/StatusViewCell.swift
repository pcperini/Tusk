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
    
    var avatarWasTapped: (() -> Void)?
    
    var status: Status? {
        didSet {
            guard let status = self.status else { return }
            
            self.avatarView.af_setImage(withURL: URL(string: status.account.avatar)!)
            self.displayNameLabel.text = status.account.name
            self.usernameLabel.text = status.account.handle
            self.timestampLabel.date = status.createdAt

            self.statusTextView.htmlText = status.content
            self.statusTextView.setNeedsLayout()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let avatarTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(avatarViewWasTapped(recognizer:)))
        self.avatarView.addGestureRecognizer(avatarTapRecognizer)
    }
    
    @objc func avatarViewWasTapped(recognizer: UIGestureRecognizer!) {
        self.avatarWasTapped?()
    }
}
