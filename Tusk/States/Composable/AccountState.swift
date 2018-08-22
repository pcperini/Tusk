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
    var pinnedStatuses: [Status] { get set }
    var following: [Account] { get set }
    var followers: [Account] { get set }
    var statuses: [Status] { get set }
    
    var statusesNextPage: RequestRange? { get set }
    var statusesPreviousPage: RequestRange? { get set }
    var statusesPaginatableData: PaginatingData<Status, Status> { mutating get set }
    
    init()
    static func pollAccount(client: Client, accountID: String?)
    func pollFollowing(client: Client)
    func pollPinnedStatuses(client: Client)
    
    func statusesProvider(range: RequestRange?) -> Request<[Status]>
}

extension AccountStateType {
    typealias SetAccount = AccountStateSetAccount<Self>
    typealias SetPinnedStatuses = AccountStateSetPinnedStatuses<Self>
    typealias SetFollowing = AccountStateSetFollowing<Self>
    typealias SetFollowers = AccountStateSetFollowers<Self>
    
    typealias SetStatuses = AccountStateSetStatuses<Self>
    typealias SetStatusesPage = AccountStateSetStatusesPage<Self>
    
    typealias PollPinnedStatuses = AccountStatePollPinnedStatuses<Self>
    typealias PollFollowing = AccountStatePollFollowing<Self>
    typealias PollFollowers = AccountStatePollFollowers<Self>
    typealias PollAccount = AccountStatePollAccount<Self>
    
    typealias PollStatuses = AccountStatePollStatuses<Self>
    typealias PollOlderStatuses = AccountStatePollOlderStatuses<Self>
    typealias PollNewerStatuses = AccountStatePollNewerStatuses<Self>

    
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
        case let action as SetStatusesPage: (state.statusesNextPage, state.statusesPreviousPage) = state.statusesUpdatedPages(pagination: action.value)
            
        case let action as PollAccount: pollAccount(client: action.client, accountID: action.accountID)
        case let action as PollPinnedStatuses: state.pollPinnedStatuses(client: action.client)
        case let action as PollFollowing: state.pollFollowing(client: action.client)
            
        case let action as PollStatuses: state.pollStatuses(client: action.client)
        case let action as PollOlderStatuses: state.pollStatuses(client: action.client, range: state.statusesNextPage)
        case let action as PollNewerStatuses: state.pollStatuses(client: action.client, range: state.statusesPreviousPage)
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
    
    mutating func pollStatuses(client: Client, range: RequestRange? = nil) {
        self.statusesPaginatableData.pollData(client: client, range: range, existingData: self.statuses, filters: []) { (
            statuses: [Status],
            pagination: Pagination?
        ) in
            GlobalStore.dispatch(SetStatuses(value: statuses))
            GlobalStore.dispatch(SetStatusesPage(value: pagination))
        }
    }
    
    func statusesProvider(range: RequestRange?) -> Request<[Status]> {
        guard let account = self.account else { fatalError("Cannot request statuses for nill account") }
        guard let range = range else { return Accounts.statuses(id: account.id) }
        return Accounts.statuses(id: account.id, range: range)
    }
    
    mutating func statusesUpdatedPages(pagination: Pagination?) -> (RequestRange?, RequestRange?) {
        return self.statusesPaginatableData.updatedPages(pagination: pagination,
                                                         nextPage: self.statusesNextPage,
                                                         previousPage: self.statusesPreviousPage)
    }
}

struct AccountStateSetAccount<State: StateType>: Action { let value: Account? }
struct AccountStateSetPinnedStatuses<State: StateType>: Action { let value: [Status] }
struct AccountStateSetFollowing<State: StateType>: Action { let value: [Account] }
struct AccountStateSetFollowers<State: StateType>: Action { let value: [Account] }

struct AccountStateSetStatuses<State: StateType>: Action { let value: [Status] }
struct AccountStateSetStatusesPage<State: StateType>: Action { let value: Pagination? }

struct AccountStatePollPinnedStatuses<State: StateType>: Action { let client: Client }
struct AccountStatePollFollowing<State: StateType>: Action { let client: Client }
struct AccountStatePollFollowers<State: StateType>: Action { let client: Client }
struct AccountStatePollAccount<State: StateType>: Action { let client: Client; let accountID: String? }

struct AccountStatePollStatuses<State: StateType>: Action { let client: Client }
struct AccountStatePollOlderStatuses<State: StateType>: Action { let client: Client }
struct AccountStatePollNewerStatuses<State: StateType>: Action { let client: Client }

struct OtherAccountState: AccountStateType {
    var account: Account? = nil
    var pinnedStatuses: [Status] = []
    var following: [Account] = []
    var followers: [Account] = []
    var statuses: [Status] = []
    
    var statusesNextPage: RequestRange? = nil
    var statusesPreviousPage: RequestRange? = nil
    lazy var statusesPaginatableData: PaginatingData<Status, Status> = PaginatingData<Status, Status>(provider: self.statusesProvider)
}
