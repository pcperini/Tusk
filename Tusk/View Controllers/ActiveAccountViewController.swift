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
    typealias StoreSubscriberStateType = ActiveAccountState
    var accountViewController: AccountViewController? {
        return self.childViewControllers.filter({ (child) in
            child is AccountViewController
        }).first as? AccountViewController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GlobalStore.subscribe(self) { (subscription) in subscription.select { (state) in state.activeAccount } }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.accountViewController?.account = GlobalStore.state.activeAccount.account
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GlobalStore.unsubscribe(self)
    }
    
    func pollAccount() {
        guard let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(ActiveAccountState.PollAccount(client: client, accountID: nil))
    }
    
    func newState(state: ActiveAccountState) {
        DispatchQueue.main.async {
            if (self.accountViewController?.account != state.account) {
                self.accountViewController?.account = state.account
            }
        }
    }
}
