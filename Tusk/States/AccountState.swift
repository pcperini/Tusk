//
//  AccountState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/12/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import MastodonKit
import ReSwift

struct AccountState: StateType {
    struct SetAccount: Action { let value: Account? }
    struct PollAccount: Action { let client: Client }
    
    var account: Account?
    
    static func reducer(action: Action, state: AccountState?) -> AccountState {
        var state = state ?? AccountState()
        
        switch action {
        case let action as SetAccount: state.account = action.value
        case let action as PollAccount: pollAccount(client: action.client)
        default: break
        }
        
        return state
    }
    
    static func pollAccount(client: Client) {
        let request = Accounts.currentUser()
        client.run(request) { (result) in
            switch result {
            case .success(let account, _): GlobalStore.dispatch(SetAccount(value: account))
            default: break
            }
        }
    }
}
