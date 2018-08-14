//
//  AccountViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/14/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit

class AccountViewController: UIViewController {
    var account: Account? { didSet { self.updateAccount() } }
    @IBOutlet var displayNameLabel: UILabel!
    
    override func viewDidLoad() {
        self.updateAccount()
    }
    
    func updateAccount() {
        guard let account = self.account else { return }
        self.displayNameLabel.text = account.name
    }
}
