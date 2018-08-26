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

struct AccountsState: StateType {
    private var allAccounts: [AccountState] = []
    var activeAccount: AccountState? {
        return self.allAccounts.first(where: { (account) in account.isActiveAccount })
    }
    
    static func reducer(action: Action, state: AccountsState?) -> AccountsState {
        var state = state ?? AccountsState()
        
        switch action {
        case let action as AccountState.PollAccount: state.allAccounts += [AccountState.reducer(action: action, state: nil)]
        default: state.allAccounts = self.passThroughReducer(action: action, state: state)
        }
        
        return state
    }
    
    private static func passThroughReducer(action: Action, state: AccountsState) -> [AccountState] {
        return state.allAccounts.map({ (account) in AccountState.reducer(action: action, state: account) })
            .dedupe(on: { (account) in account.hashValue })
    }
    
    func accountWithID(id: String) -> AccountState? {
        return self.allAccounts.first(where: { (account) in account.account?.id == id })
    }
}
