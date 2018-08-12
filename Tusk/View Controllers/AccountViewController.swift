//
//  AccountViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/12/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift

class AccountViewController: UIViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = AccountState
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GlobalStore.subscribe(self) { (subscription) in subscription.select { (state) in state.account } }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pollAccount()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GlobalStore.unsubscribe(self)
    }
    
    func pollAccount() {
        guard let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(AccountState.PollAccount(client: client))
    }
    
    func newState(state: AccountState) {
    }
}
