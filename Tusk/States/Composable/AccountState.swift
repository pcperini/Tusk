//
//  AccountState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/21/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import MastodonKit
import ReSwift

protocol AccountStateType: StateType {
    var account: Account? { get set }
    var pinnedStatuses: [Status]  { get set }
    var following: [Account]  { get set }
    var followers: [Account]  { get set }
    var statuses: [Status]  { get set }
    
    init()
    static func pollAccount(client: Client, accountID: String?)
    func pollFollowing(client: Client)
    func pollPinnedStatuses(client: Client)
}

extension AccountStateType {
    typealias SetAccount = AccountStateSetAccount<Self>
    typealias SetPinnedStatuses = AccountStateSetPinnedStatuses<Self>
    typealias SetFollowing = AccountStateSetFollowing<Self>
    typealias SetFollowers = AccountStateSetFollowers<Self>
    typealias SetStatuses = AccountStateSetStatuses<Self>
    
    typealias PollPinnedStatuses = AccountStatePollPinnedStatuses<Self>
    typealias PollFollowing = AccountStatePollFollowing<Self>
    typealias PollFollowers = AccountStatePollFollowers<Self>
    typealias PollStatuses = AccountStatePollStatuses<Self>
    typealias PollAccount = AccountStatePollAccount<Self>
    
    static func reducer(action: Action, state: Self?) -> Self {
        var state = state ?? Self.init()
        
        switch action {
        case let action as SetAccount: do {
            guard state.account != action.value else { break }
            state = Self.init()
            state.account = action.value
            }
        case let action as SetPinnedStatuses: state.pinnedStatuses = action.value
        case let action as SetFollowing: state.following = action.value
        case let action as SetFollowers: state.followers = action.value
        case let action as SetStatuses: state.statuses = action.value
        case let action as PollAccount: pollAccount(client: action.client, accountID: action.accountID)
        case let action as PollPinnedStatuses: state.pollPinnedStatuses(client: action.client)
        case let action as PollFollowing: state.pollFollowing(client: action.client)
        default: break
        }
        
        return state
    }
    
    static func pollAccount(client: Client, accountID: String? = nil) {
        let request = accountID == nil ? Accounts.currentUser() : Accounts.account(id: accountID!)
        client.run(request) { (result) in
            switch result {
            case .success(let account, _): do {
                GlobalStore.dispatch(SetAccount(value: account))
                GlobalStore.dispatch(PollPinnedStatuses(client: client))
                GlobalStore.dispatch(PollFollowing(client: client))
                print("success", #file, #line)
                }
            case .failure(let error): print(error, #file, #line)
            }
        }
    }
    
    func pollFollowing(client: Client) {
        guard let account = self.account else { return }
        let request = Accounts.following(id: account.id, range: .limit(80))
        client.run(request) { (result) in
            switch result {
            case .success(let following, _): do {
                GlobalStore.dispatch(SetFollowing(value: following))
                print("success", #file, #line)
                }
            case .failure(let error): print(error, #file, #line)
            }
        }
    }
    
    func pollPinnedStatuses(client: Client) {
        guard let account = self.account else { return }
        let request = Accounts.statuses(id: account.id,
                                        mediaOnly: false,
                                        pinnedOnly: true,
                                        excludeReplies: true,
                                        range: .limit(40))
        client.run(request) { (result) in
            switch result {
            case .success(let statuses, _): do {
                GlobalStore.dispatch(SetPinnedStatuses(value: statuses))
                print("success", #file, #line)
                }
            case .failure(let error): print(error, #file, #line)
            }
        }
    }
}

struct AccountStateSetAccount<State: StateType>: Action { let value: Account? }
struct AccountStateSetPinnedStatuses<State: StateType>: Action { let value: [Status] }
struct AccountStateSetFollowing<State: StateType>: Action { let value: [Account] }
struct AccountStateSetFollowers<State: StateType>: Action { let value: [Account] }
struct AccountStateSetStatuses<State: StateType>: Action { let value: [Status] }

struct AccountStatePollPinnedStatuses<State: StateType>: Action { let client: Client }
struct AccountStatePollFollowing<State: StateType>: Action { let client: Client }
struct AccountStatePollFollowers<State: StateType>: Action { let client: Client }
struct AccountStatePollStatuses<State: StateType>: Action { let client: Client }
struct AccountStatePollAccount<State: StateType>: Action { let client: Client; let accountID: String? }

struct OtherAccountState: AccountStateType {
    var account: Account? = nil
    var pinnedStatuses: [Status] = []
    var following: [Account] = []
    var followers: [Account] = []
    var statuses: [Status] = []
}
