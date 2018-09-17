//
//  AccountState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/21/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import MastodonKit
import ReSwift

protocol AccountAction: Action { var account: AccountType { get } }
protocol AccountPollingAction: AccountAction, PollAction {}

struct AccountState: StateType, StatusViewableState {
    private struct SetAccount: AccountAction { let account: AccountType; let active: Bool }
    struct SetPinnedStatuses: AccountAction { let value: [Status]; let account: AccountType }
    struct SetRelationship: AccountAction { let value: Relationship?; let account: AccountType }
    
    struct SetFollowing: AccountAction { let value: [Account]; let account: AccountType }
    struct SetFollowingPage: AccountAction { let value: Pagination?; let account: AccountType }

    struct SetFollowers: AccountAction { let value: [Account]; let account: AccountType }
    private struct SetFollowersPage: AccountAction { let value: Pagination?; let account: AccountType }
    
    struct SetStatuses: AccountAction { let value: [Status]; let account: AccountType }
    private struct SetStatusesPage: AccountAction { let value: Pagination?; let account: AccountType }
    
    struct PollAccount: Action { let client: Client; let account: AccountType? }
    struct PollPinnedStatuses: AccountAction { let client: Client; let account: AccountType }
    struct PollRelationship: AccountAction { let client: Client; let account: AccountType }
    
    struct PollFollowing: AccountAction { let client: Client; let account: AccountType }
    struct PollOlderFollowing: AccountPollingAction { let client: Client; let account: AccountType }
    struct PollNewerFollowing: AccountPollingAction { let client: Client; let account: AccountType }
    
    struct PollFollowers: AccountAction { let client: Client; let account: AccountType }
    struct PollOlderFollowers: AccountPollingAction { let client: Client; let account: AccountType }
    struct PollNewerFollowers: AccountPollingAction { let client: Client; let account: AccountType }
    
    struct PollStatuses: AccountPollingAction { let client: Client; let account: AccountType }
    struct PollOlderStatuses: AccountPollingAction { let client: Client; let account: AccountType }
    struct PollNewerStatuses: AccountPollingAction { let client: Client; let account: AccountType }
    
    struct ToggleFollowing: AccountAction { let client: Client; let account: AccountType }
    struct ToggleMuting: AccountAction { let client: Client; let account: AccountType }
    struct ToggleReposts: AccountAction { let client: Client; let account: AccountType }
    struct ToggleBlocking: AccountAction { let client: Client; let account: AccountType }
    
    struct UpdateBio: AccountAction { let client: Client; let account: AccountType; let value: String }
    struct UpdateLocked: AccountAction { let client: Client; let account: AccountType; let value: Bool }
    struct UpdateDisplayName: AccountAction { let client: Client; let account: AccountType; let value: String }
    struct UpdateFields: AccountAction { let client: Client; let account: AccountType; let value: [[String: String]] }
    
    var isActiveAccount: Bool = false
    var account: AccountType? = nil
    var pinnedStatuses: [Status] = []
    var following: [Account] = []
    var followers: [Account] = []
    var relationship: Relationship? = nil
    
    var statuses: [Status] = []
    
    private var statusesNextPage: RequestRange? = nil
    private var statusesPreviousPage: RequestRange? = nil
    private lazy var statusesPaginatableData: PaginatingData<Status, Status> = PaginatingData<Status, Status>(provider: self.statusesProvider)
    
    private var followersNextPage: RequestRange? = nil
    private var followersPreviousPage: RequestRange? = nil
    private lazy var followersPaginatableData: PaginatingData<Account, Account> = PaginatingData<Account, Account>(provider: self.followersProvider)
    
    private var followingNextPage: RequestRange? = nil
    private var followingPreviousPage: RequestRange? = nil
    private lazy var followingPaginatableData: PaginatingData<Account, Account> = PaginatingData<Account, Account>(provider: self.followingProvider)
    
    var hashValue: Int { return (self.account?.hashValue ?? 0) + (self.isActiveAccount ? 1 : 0) }
    
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
        
        guard let action = action as? AccountAction, state.account == nil || state.account?.id == action.account.id else { return state }
        
        switch action {
        case let action as SetAccount: do {
            state.account = action.account
            state.isActiveAccount = action.active || state.isActiveAccount
            }
        case let action as SetPinnedStatuses: state.pinnedStatuses = action.value
        case let action as SetRelationship: state.relationship = action.value
            
        case let action as SetFollowing: state.following = action.value
        case let action as SetFollowingPage: (state.followingNextPage, state.followingPreviousPage) = state.followingUpdatedPages(pagination: action.value)
            
        case let action as SetFollowers: state.followers = action.value
        case let action as SetFollowersPage: (state.followersNextPage, state.followersPreviousPage) = state.followersUpdatedPages(pagination: action.value)
            
        case let action as SetStatuses: state.statuses = action.value
        case let action as SetStatusesPage: (state.statusesNextPage, state.statusesPreviousPage) = state.statusesUpdatedPages(pagination: action.value)
            
        case let action as PollPinnedStatuses: state.pollPinnedStatuses(client: action.client)
        case let action as PollRelationship: state.pollRelationship(client: action.client)
            
        case let action as PollFollowing: state.pollFollowing(client: action.client, account: action.account)
        case let action as PollOlderFollowing: state.pollFollowing(client: action.client, account: action.account, range: state.followingNextPage)
        case let action as PollNewerFollowing: state.pollFollowing(client: action.client, account: action.account, range: state.followingPreviousPage)
            
        case let action as PollStatuses: state.pollStatuses(client: action.client, account: action.account)
        case let action as PollOlderStatuses: state.pollStatuses(client: action.client, account: action.account, range: state.statusesNextPage)
        case let action as PollNewerStatuses: state.pollStatuses(client: action.client, account: action.account, range: state.statusesPreviousPage)
            
        case let action as PollFollowers: state.pollFollowers(client: action.client, account: action.account)
        case let action as PollOlderFollowers: state.pollFollowers(client: action.client, account: action.account, range: state.followersNextPage)
        case let action as PollNewerFollowers: state.pollFollowers(client: action.client, account: action.account, range: state.followersPreviousPage)
            
        case let action as ToggleFollowing: state.toggleFollowing(client: action.client, account: action.account)
        case let action as ToggleMuting: state.toggleMuting(client: action.client, account: action.account)
        case let action as ToggleReposts: state.toggleReposts(client: action.client, account: action.account)
        case let action as ToggleBlocking: state.toggleBlocking(client: action.client, account: action.account)
            
        case let action as UpdateBio: state.update(client: action.client, note: action.value)
        case let action as UpdateLocked: state.update(client: action.client, locked: action.value)
        case let action as UpdateDisplayName: state.update(client: action.client, displayName: action.value)
        case let action as UpdateFields: state.update(client: action.client, fields: action.value)
            
        default: break
        }
        
        return state
    }
    
    static func pollAccount(client: Client, accountID: String? = nil) {
        let request = accountID == nil ? Accounts.currentUser() : Accounts.account(id: accountID!)
        client.run(request: request, success: { (resp, _) in
            GlobalStore.dispatch(SetAccount(account: resp, active: accountID == nil))
            GlobalStore.dispatch(PollPinnedStatuses(client: client, account: resp))
            GlobalStore.dispatch(PollRelationship(client: client, account: resp))
        })
    }
    
    func pollPinnedStatuses(client: Client) {
        guard let account = self.account else { return }
        let request = Accounts.statuses(id: account.id,
                                        mediaOnly: false,
                                        pinnedOnly: true,
                                        excludeReplies: true,
                                        range: .limit(40))
        client.run(request: request, success: { (resp, _) in
            GlobalStore.dispatch(SetPinnedStatuses(value: resp, account: account))
        })
    }
    
    func pollRelationship(client: Client) {
        guard let account = self.account else { return }
        let request = Accounts.relationships(ids: [account.id])
        client.run(request: request, success: { (resp, _) in
            GlobalStore.dispatch(SetRelationship(value: resp.first, account: account))
        })
    }
    
    mutating func pollStatuses(client: Client, account: AccountType, range: RequestRange? = nil) {
        self.statusesPaginatableData.pollData(client: client, range: range, existingData: self.statuses, filters: []) { (
            statuses: [Status],
            pagination: Pagination?
        ) in
            GlobalStore.dispatch(SetStatuses(value: statuses, account: account))
            GlobalStore.dispatch(SetStatusesPage(value: pagination, account: account))
        }
    }
    
    func update(client: Client,
                displayName: String? = nil,
                note: String? = nil,
                avatar: MediaAttachment? = nil,
                header: MediaAttachment? = nil,
                locked: Bool? = nil,
                fields: [[String: String]]? = nil) {
        let request = Accounts.updateCurrentUser(displayName: displayName,
                                                 note: note,
                                                 avatar: avatar,
                                                 header: header,
                                                 locked: locked,
                                                 fields: fields)
        client.run(request: request, success: { (resp, _) in
            GlobalStore.dispatch(SetAccount(account: resp, active: self.isActiveAccount))
        })
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
    
    mutating func pollFollowers(client: Client, account: AccountType, range: RequestRange? = nil) {
        self.followersPaginatableData.pollData(client: client, range: range, existingData: self.followers, filters: []) { (
            followers: [Account],
            pagination: Pagination?
        ) in
            GlobalStore.dispatch(SetFollowers(value: followers, account: account))
            GlobalStore.dispatch(SetFollowersPage(value: pagination, account: account))
        }
    }
    
    func followersProvider(range: RequestRange?) -> Request<[Account]> {
        guard let account = self.account else { fatalError("Cannot request statuses for nil account") }
        guard let range = range else { return Accounts.followers(id: account.id, range: .limit(80)) }
        return Accounts.followers(id: account.id, range: range)
    }
    
    mutating func followersUpdatedPages(pagination: Pagination?) -> (RequestRange?, RequestRange?) {
        return self.followersPaginatableData.updatedPages(pagination: pagination,
                                                          nextPage: self.followersNextPage,
                                                          previousPage: self.followersPreviousPage)
    }
    
    mutating func pollFollowing(client: Client, account: AccountType, range: RequestRange? = nil) {
        self.followingPaginatableData.pollData(client: client, range: range, existingData: self.following, filters: []) { (
            following: [Account],
            pagination: Pagination?
        ) in
            GlobalStore.dispatch(SetFollowing(value: following, account: account))
            GlobalStore.dispatch(SetFollowingPage(value: pagination, account: account))
        }
    }
    
    func followingProvider(range: RequestRange?) -> Request<[Account]> {
        guard let account = self.account else { fatalError("Cannot request statuses for nil account") }
        guard let range = range else { return Accounts.following(id: account.id, range: .limit(80)) }
        return Accounts.following(id: account.id, range: range)
    }
    
    mutating func followingUpdatedPages(pagination: Pagination?) -> (RequestRange?, RequestRange?) {
        return self.followingPaginatableData.updatedPages(pagination: pagination,
                                                          nextPage: self.followingNextPage,
                                                          previousPage: self.followingPreviousPage)
    }
    
    func toggleFollowing(client: Client, account: AccountType) {
        guard let relationship = self.relationship else { return }
        let start = !relationship.following
        
        let request = start ? Accounts.follow(id: account.id) : Accounts.unfollow(id: account.id)
        client.run(request: request, success: { (resp, _) in
            GlobalStore.dispatch(SetRelationship(value: resp, account: account))
        })
    }
    
    func toggleMuting(client: Client, account: AccountType) {
        guard let relationship = self.relationship else { return }
        let start = !relationship.muting
        
        let request = start ? Accounts.mute(id: account.id) : Accounts.unmute(id: account.id)
        client.run(request: request, success: { (resp, _) in
            GlobalStore.dispatch(SetRelationship(value: resp, account: account))
        })
    }
    
    func toggleReposts(client: Client, account: AccountType) {
        guard let relationship = self.relationship else { return }
        let start = !relationship.showingReblogs

        let request = start ? Accounts.showReblogs(id: account.id) : Accounts.hideReblogs(id: account.id)
        client.run(request: request, success: { (resp, _) in
            GlobalStore.dispatch(SetRelationship(value: resp, account: account))
        })
    }
    
    func toggleBlocking(client: Client, account: AccountType) {
        guard let relationship = self.relationship else { return }
        let start = !relationship.blocking
        
        let request = start ? Accounts.block(id: account.id) : Accounts.unblock(id: account.id)
        client.run(request: request, success: { (resp, _) in
            GlobalStore.dispatch(SetRelationship(value: resp, account: account))
        })
    }
}
