//
//  AccountViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/12/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift

class ActiveAccountViewController: UIViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = AccountState
    var accountViewController: AccountViewController? {
        return self.childViewControllers.filter({ (child) in
            (child as? AccountViewController) != nil
        }).first as? AccountViewController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GlobalStore.subscribe(self) { (subscription) in subscription.select { (state) in state.account } }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.accountViewController?.account = GlobalStore.state.account.activeAccount
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GlobalStore.unsubscribe(self)
    }
    
    func pollAccount() {
        guard let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(AccountState.PollActiveAccount(client: client))
    }
    
    func newState(state: AccountState) {
        DispatchQueue.main.async {
            if (self.accountViewController?.account != state.activeAccount) {
                self.accountViewController?.account = state.activeAccount
            }
        }
    }
}
