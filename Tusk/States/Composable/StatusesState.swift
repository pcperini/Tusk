//
//  StatusesState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/20/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import MastodonKit
import ReSwift

protocol StatusesState: StatusViewableState, PaginatableState where DataType == Status {
    associatedtype SetFilters: Action
    associatedtype SetStatuses: Action
    associatedtype SetPage: Action
    
    var statuses: [Status] { get set }
    var unsuppressedStatusIDs: [String] { get set }
    var filters: [(Status) -> Bool] { get set }
    
    init()
    func pollStatuses(client: Client, range: RequestRange?)
    mutating func updateStatus(status: Status)
}

extension StatusesState {
    typealias SetFilters = StatusesStateSetFilters<Self>
    typealias SetStatuses = StatusesStateSetStatuses<Self>
    typealias SetUnsuppressedStatusIDs = StatusesStateSetUnsuppressedStatusIDs
    typealias SetPage = StatusesStateSetPage<Self>
    
    typealias LoadUnsuppressedStatusIDs = StatusesStateLoadUnsuppressedStatusIDs
    typealias PollStatuses = StatusesStatePollStatuses<Self>
    typealias PollOlderStatuses = StatusesStatePollOlderStatuses<Self>
    typealias PollNewerStatuses = StatusesStatePollNewerStatuses<Self>
    typealias PollFilters = StatusesStatePollFilters
    typealias UpdateStatus = StatusesStateUpdateStatus
    typealias InsertStatus = StatusesStateInsertStatus<Self>
    typealias RemoveStatus = StatusesStateRemoveStatus
        
    static func reducer(action: Action, state: Self?) -> Self {
        var state = state ?? Self.init()
        
        switch action {
        case let action as SetFilters: state.updateStatuses(statuses: state.statuses, withFilters: action.value)
        case let action as SetStatuses: state.updateStatuses(statuses: action.value, withFilters: state.filters)
        case let action as SetUnsuppressedStatusIDs: state.saveUnsuppressedStatusIDs(statusIDs: action.value)
        case let action as SetPage: (state.nextPage, state.previousPage) = state.paginatingData.updatedPages(pagination: action.value,
                                                                                                             nextPage: state.nextPage,
                                                                                                             previousPage: state.previousPage)
        case is LoadUnsuppressedStatusIDs: state.unsuppressedStatusIDs = self.cloudLoadUnsuppressedStatusIDs()
        case let action as PollStatuses: state.pollStatuses(client: action.client)
        case let action as PollOlderStatuses: state.pollStatuses(client: action.client, range: state.nextPage)
        case let action as PollNewerStatuses: state.pollStatuses(client: action.client, range: state.previousPage)
        case let action as PollFilters: state.pollFilters(client: action.client)
        case let action as UpdateStatus: state.updateStatus(status: action.value)
        case let action as InsertStatus: state.statuses.insert(action.value, at: 0)
        case let action as RemoveStatus: state.removeStatus(status: action.value)
        default: break
        }
        
        return state
    }
    
    func pollStatuses(client: Client, range: RequestRange? = nil) {
        self.paginatingData.pollData(client: client, range: range, existingData: self.statuses, filters: self.filters) { (
            statuses: [Status],
            pagination: Pagination?
        ) in
            DispatchQueue.main.async {
                GlobalStore.dispatch(SetStatuses(value: statuses))
                GlobalStore.dispatch(SetPage(value: pagination))
            }
        }
    }
    
    func pollFilters(client: Client) {
        let request = Filters.all()
        client.run(request: request, success: { (resp, _) in
            GlobalStore.dispatch(SetFilters(value: self.filters + resp.map { $0.filterFunction }))
        })
    }
    
    mutating func updateStatuses(statuses: [Status], withFilters filters: [(Status) -> Bool]) {
        self.filters = filters
        self.statuses = filters.reduce(statuses, { (all, next) in all.filter(next) })
    }
    
    mutating func saveUnsuppressedStatusIDs(statusIDs: [String]) {
        self.unsuppressedStatusIDs = statusIDs
        Self.cloudSyncUnsuppressedStatusIDs(statusIDs: statusIDs)
    }
    
    static func cloudLoadUnsuppressedStatusIDs() -> [String] {
        let statusIDs = NSUbiquitousKeyValueStore.default.dictionary(forKey: "UnsuppressedStatusIDs") as? [String: Date] ?? [:]
        return Array(statusIDs.keys)
    }
    
    static func cloudSyncUnsuppressedStatusIDs(statusIDs: [String]) {
        let stored = statusIDs.reduce([:]) { (all, next) in
            all.merging([next: Date()], uniquingKeysWith: { (lhs, rhs) in lhs })
        }
        
        let storage = NSUbiquitousKeyValueStore.default.dictionary(forKey: "UnsuppressedStatusIDs") as? [String: Date] ?? [:]
            .filter({
                Date().timeIntervalSince($0.value) <= 24 * 60 * 60
            })
            .merging(stored, uniquingKeysWith: { (lhs, rhs) in max(lhs, rhs) })
        
        NSUbiquitousKeyValueStore.default.set(storage, forKey: "UnsuppressedStatusIDs")
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    mutating func updateStatus(status: Status) {
        // Author's note: reblogs are handled as wrappers around the origin status
        // When the active user reblogs a post, the API returns a NEW status, a wrapper post, to replace the original
        // When the active user unreblogs a post, the API returns the ORIGINAL status, newly-devoid of wrapper
        // This causeses unnecessary diffing in table UIs, so instead we'll just update the original status both times
        
        if let index = self.statuses.index(where: { $0.id == status.id }) {
            self.statuses[index] = status
        } else if let reblog = status.reblog, let index = self.statuses.index(where: { $0.id == status.reblog?.id }) {
            self.statuses[index] = reblog
        } else if let reblog = status.reblog, let index = self.statuses.index(where: { $0.reblog?.id == reblog.id }) {
            self.statuses[index] = try! self.statuses[index].cloned(changes: ["reblog": reblog.jsonValue!])
        } else if let index = self.statuses.index(where: { $0.reblog?.id == status.id }) {
            self.statuses[index] = try! self.statuses[index].cloned(changes: ["reblog": status.jsonValue!])
        }
    }
    
    mutating func removeStatus(status: Status) {
        self.statuses = self.statuses.filter { $0.id != status.id && $0.reblog?.id != status.id }
    }
}

struct StatusesStateSetFilters<State: StateType>: Action { let value: [(Status) -> Bool] }
struct StatusesStateSetStatuses<State: StateType>: Action { let value: [Status] }
struct StatusesStateSetUnsuppressedStatusIDs: Action { let value: [String] }
struct StatusesStateSetPage<State: StateType>: Action { let value: Pagination? }
struct StatusesStateLoadUnsuppressedStatusIDs: Action {}
struct StatusesStatePollStatuses<State: StateType>: PollAction { let client: Client }
struct StatusesStatePollOlderStatuses<State: StateType>: PollAction { let client: Client }
struct StatusesStatePollNewerStatuses<State: StateType>: PollAction { let client: Client }
struct StatusesStatePollFilters: PollAction { let client: Client }
struct StatusesStateUpdateStatus: Action { let value: Status }
struct StatusesStateInsertStatus<State: StateType>: Action { let value: Status }
struct StatusesStateRemoveStatus: Action { let value: Status }

