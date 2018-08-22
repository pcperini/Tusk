//
//  AccountsState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/22/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import MastodonKit
import ReSwift
import KeychainAccess

struct AccountsState: StateType {
    private var allAccounts: Set<AccountState> = Set<AccountState>()    
    var activeAccount: AccountState? {
        return self.allAccounts.first(where: { (account) in account.isActiveAccount })
    }
    
    static func reducer(action: Action, state: AccountsState?) -> AccountsState {
        var state = state ?? AccountsState()
        
        switch action {
        case let action as AccountState.PollAccount: state.allAccounts = state.allAccounts.union([AccountState.reducer(action: action, state: nil)])
        default: state.allAccounts = Set(state.allAccounts.map({ (account) in AccountState.reducer(action: action, state: account) }))
        }
        
        return state
    }
    
    func accountWithID(id: String) -> AccountState? {
        return self.allAccounts.first(where: { (account) in account.account?.id == id })
    }
}
