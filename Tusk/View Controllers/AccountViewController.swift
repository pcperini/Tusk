//
//  AccountViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/14/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit

class AccountViewController: UITableViewController {
    var account: Account? { didSet { self.updateAccount() } }
    
    @IBOutlet var headerImageView: UIImageView!
    @IBOutlet var avatarView: ImageView!
    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var bioTextView: TextView!
    @IBOutlet var pronounLabel: UILabel!
    
    override func viewDidLoad() {
        self.updateAccount()
        
        // TODO: Fix this magic number
        if let headerView = self.tableView.tableHeaderView {
            var frame = headerView.frame
            frame.size.height = headerView.subviews.last!.systemLayoutSizeFitting(UILayoutFittingExpandedSize).height + 30
            headerView.frame = frame
            self.tableView.reloadData()
        }
    }
    
    func updateAccount() {
        guard let account = self.account else { return }
        self.parent?.navigationItem.title = account.name
        
        self.headerImageView.af_setImage(withURL: URL(string: account.header)!)
        self.avatarView.af_setImage(withURL: URL(string: account.avatar)!)
        self.displayNameLabel.text = account.name
        self.usernameLabel.text = account.handle
        self.bioTextView.text = account.plainNote
        
//        self.pronounLabel.text = account.
    }
}
