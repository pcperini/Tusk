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
    struct SetAccountPinnedStatuses: Action { let value: [Status] }
    struct SetAccountFollowing: Action {
        let value: [Account]
        let account: Account
    }
    
    struct PollActiveAccount: Action { let client: Client }
    struct PollAccountPinnedStatuses: Action {
        let client: Client
        let account: Account
    }
    struct PollAccountFollowing: Action {
        let client: Client
        let account: Account
    }
    
    var activeAccount: Account?
    var pinnedStatuses: [Account: [Status]] = [:]
    var following: [Account: [Account]] = [:]
    
    static func reducer(action: Action, state: AccountState?) -> AccountState {
        var state = state ?? AccountState()
        
        switch action {
        case let action as SetAccount: state.activeAccount = action.value
        case let action as SetAccountPinnedStatuses: state.setAccountPinnedStatuses(statuses: action.value)
        case let action as SetAccountFollowing: state.following[action.account] = action.value
        case let action as PollActiveAccount: pollAccount(client: action.client)
        case let action as PollAccountPinnedStatuses: pollPinnedStatuses(client: action.client, account: action.account)
        case let action as PollAccountFollowing: pollAccountFollowing(client: action.client, account: action.account)
        default: break
        }
        
        return state
    }
    
    mutating func setAccountPinnedStatuses(statuses: [Status]) {
        guard let status = statuses.first else { return }
        self.pinnedStatuses[status.account] = statuses
    }
    
    static func pollAccount(client: Client) {
        let request = Accounts.currentUser()
        client.run(request) { (result) in
            switch result {
            case .success(let account, _): do {
                GlobalStore.dispatch(SetAccount(value: account))
                GlobalStore.dispatch(PollAccountPinnedStatuses(client: client, account: account))
                GlobalStore.dispatch(PollAccountFollowing(client: client, account: account))
                print("success", #file, #line)
                }
            case .failure(let error): print(error, #file, #line)
            }
        }
    }
    
    static func pollAccountFollowing(client: Client, account: Account) {
        let request = Accounts.following(id: account.id, range: .limit(80))
        client.run(request) { (result) in
            switch result {
            case .success(let following, _): do {
                GlobalStore.dispatch(SetAccountFollowing(value: following, account: account))
                print("success", #file, #line)
                }
            case .failure(let error): print(error, #file, #line)
            }
        }
    }
    
    static func pollPinnedStatuses(client: Client, account: Account) {
        let request = Accounts.statuses(id: account.id,
                                        mediaOnly: false,
                                        pinnedOnly: true,
                                        excludeReplies: true,
                                        range: .limit(40))
        client.run(request) { (result) in
            switch result {
            case .success(let statuses, _): do {
                GlobalStore.dispatch(SetAccountPinnedStatuses(value: statuses))
                print("success", #file, #line)
                }
            case .failure(let error): print(error, #file, #line)
            }
        }
    }
}
