//
//  AccountStatusesViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/22/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift
import MastodonKit

class AccountStatusesViewController: StatusesContainerViewController<AccountState> {
    var account: Account! { didSet { if (oldValue != self.account) { self.updateAccount() } } }
    
    func updateAccount() {
//        guard let account = self.account else { return }
    }
    
    override func setUpSubscriptions() {
        GlobalStore.subscribe(self) { (subscription) in subscription.select { (state) in
            return state.accounts.accountWithID(id: self.account.id)!
        } }
    }
    
    override func pollStatusesAction(client: Client, pageDirection: PageDirection) -> PollAction {
        switch pageDirection {
        case .NextPage: return StoreSubscriberStateType.PollOlderStatuses(client: client, account: self.account)
        case .PreviousPage: return StoreSubscriberStateType.PollNewerStatuses(client: client, account: self.account)
        case .Reload: return StoreSubscriberStateType.PollStatuses(client: client, account: self.account)
        }
    }
    
    override func newState(state: AccountState) {
        super.newState(state: state)
    }
}
