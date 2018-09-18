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
    var account: Account!

    override func state(appState: AppState) -> AccountState {
        return appState.accounts.accountWithID(id: self.account.id)!
    }
    
    override func pollStatusesAction(client: Client, pageDirection: PageDirection) -> PollAction {
        switch pageDirection {
        case .NextPage: return AccountState.PollOlderStatuses(client: client, account: self.account)
        case .PreviousPage: return AccountState.PollNewerStatuses(client: client, account: self.account)
        case .Reload: return AccountState.PollStatuses(client: client, account: self.account)
        }
    }
}
