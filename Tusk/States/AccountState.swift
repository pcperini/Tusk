//
//  AccountState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/21/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import MastodonKit
import ReSwift

protocol AccountAction: Action { var account: Account { get } }

struct AccountState: StateType {
    private struct SetAccount: AccountAction { let account: Account; let active: Bool }
    struct SetPinnedStatuses: AccountAction { let value: [Status]; let account: Account }
    struct SetFollowing: AccountAction { let value: [Account]; let account: Account }
    struct SetFollowers: AccountAction { let value: [Account]; let account: Account }
    
    struct SetStatuses: AccountAction { let value: [Status]; let account: Account }
    struct SetStatusesPage: AccountAction { let value: Pagination?; let account: Account }
    
    struct PollAccount: Action { let client: Client; let account: Account? }
    struct PollPinnedStatuses: AccountAction { let client: Client; let account: Account }
    struct PollFollowing: AccountAction { let client: Client; let account: Account }
    struct PollFollowers: AccountAction { let client: Client; let account: Account }
    
    struct PollStatuses: AccountAction { let client: Client; let account: Account }
    struct PollOlderStatuses: AccountAction { let client: Client; let account: Account }
    struct PollNewerStatuses: AccountAction { let client: Client; let account: Account }
    
    var isActiveAccount: Bool = false
    var account: Account? = nil
    var pinnedStatuses: [Status] = []
    var following: [Account] = []
    var followers: [Account] = []
    var statuses: [Status] = []
    
    var statusesNextPage: RequestRange? = nil
    var statusesPreviousPage: RequestRange? = nil
    lazy var statusesPaginatableData: PaginatingData<Status, Status> = PaginatingData<Status, Status>(provider: self.statusesProvider)
    
    static func reducer(action: Action, state: AccountState?) -> AccountState {
        var state = state ?? AccountState()
        
        switch action {
        case let action as PollAccount: do {
            pollAccount(client: action.client, accountID: action.account?.id)
            state = AccountState()
            state.account = action.account
            state.isActiveAccount = action.account?.id == nil
            return state
            }
        default: break
        }
        
        guard let action = action as? AccountAction, state.account == nil || state.account == action.account else { return state }
        
        switch action {
        case let action as SetAccount: do {
            state.account = action.account
            state.isActiveAccount = action.active
            }
        case let action as SetPinnedStatuses: state.pinnedStatuses = action.value
        case let action as SetFollowing: state.following = action.value
        case let action as SetFollowers: state.followers = action.value
            
        case let action as SetStatuses: state.statuses = action.value
        case let action as SetStatusesPage: (state.statusesNextPage, state.statusesPreviousPage) = state.statusesUpdatedPages(pagination: action.value)
            
        case let action as PollPinnedStatuses: state.pollPinnedStatuses(client: action.client)
        case let action as PollFollowing: state.pollFollowing(client: action.client)
            
        case let action as PollStatuses: state.pollStatuses(client: action.client, account: action.account)
        case let action as PollOlderStatuses: state.pollStatuses(client: action.client, account: action.account, range: state.statusesNextPage)
        case let action as PollNewerStatuses: state.pollStatuses(client: action.client, account: action.account, range: state.statusesPreviousPage)
        default: break
        }
        
        return state
    }
    
    static func pollAccount(client: Client, accountID: String? = nil) {
        let request = accountID == nil ? Accounts.currentUser() : Accounts.account(id: accountID!)
        client.run(request) { (result) in
            switch result {
            case .success(let account, _): do {
                GlobalStore.dispatch(SetAccount(account: account, active: accountID == nil))
                GlobalStore.dispatch(PollPinnedStatuses(client: client, account: account))
                GlobalStore.dispatch(PollFollowing(client: client, account: account))
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
                GlobalStore.dispatch(SetFollowing(value: following, account: account))
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
                GlobalStore.dispatch(SetPinnedStatuses(value: statuses, account: account))
                print("success", #file, #line)
                }
            case .failure(let error): print(error, #file, #line)
            }
        }
    }
    
    mutating func pollStatuses(client: Client, account: Account, range: RequestRange? = nil) {
        self.statusesPaginatableData.pollData(client: client, range: range, existingData: self.statuses, filters: []) { (
            statuses: [Status],
            pagination: Pagination?
        ) in
            GlobalStore.dispatch(SetStatuses(value: statuses, account: account))
            GlobalStore.dispatch(SetStatusesPage(value: pagination, account: account))
        }
    }
    
    func statusesProvider(range: RequestRange?) -> Request<[Status]> {
        guard let account = self.account else { fatalError("Cannot request statuses for nil account") }
        guard let range = range else { return Accounts.statuses(id: account.id) }
        return Accounts.statuses(id: account.id, range: range)
    }
    
    mutating func statusesUpdatedPages(pagination: Pagination?) -> (RequestRange?, RequestRange?) {
        return self.statusesPaginatableData.updatedPages(pagination: pagination,
                                                         nextPage: self.statusesNextPage,
                                                         previousPage: self.statusesPreviousPage)
    }
}

extension AccountState: Hashable {
    static func == (lhs: AccountState, rhs: AccountState) -> Bool {
        print("\(lhs.account?.id) == \(rhs.account?.id) [\(lhs.account == rhs.account)] && \(lhs.isActiveAccount) == \(rhs.isActiveAccount) [\(lhs.isActiveAccount == rhs.isActiveAccount)]")
        return lhs.account == rhs.account && lhs.isActiveAccount == rhs.isActiveAccount
    }
    
    var hashValue: Int {
        let hash = (self.account?.id.hashValue ?? 0) + (self.isActiveAccount ? 1 : 0)
        print("\n\nHash for account \(self.account?.id) \(hash)")
        return hash
    }
    
    
}
