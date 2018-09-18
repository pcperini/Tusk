//
//  AccountViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/12/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift

class ActiveAccountViewController: UIViewController {
    var accountViewController: AccountViewController? {
        return self.childViewControllers.filter({ (child) in
            child is AccountViewController
        }).first as? AccountViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.accountViewController?.account = GlobalStore.state.accounts.activeAccount?.account
    }
    
    func pollAccount() {
        guard let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(AccountState.PollAccount(client: client, account: nil))
    }
}
