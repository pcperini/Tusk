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
    var statuses: [Status] { get set }
    var baseFilters: [(Status) -> Bool] { get set }
    var filters: [(Status) -> Bool] { get }
    
    init()
    func pollStatuses(client: Client, range: RequestRange?)
    mutating func updateStatus(status: Status)
}

extension StatusesState {
    typealias SetStatuses = StatusesStateSetStatuses<Self>
    typealias SetPage = StatusesStateSetPage<Self>
    
    typealias PollStatuses = StatusesStatePollStatuses<Self>
    typealias PollOlderStatuses = StatusesStatePollOlderStatuses<Self>
    typealias PollNewerStatuses = StatusesStatePollNewerStatuses<Self>
    typealias UpdateStatus = StatusesStateUpdateStatus
    typealias InsertStatus = StatusesStateInsertStatus<Self>
    typealias RemoveStatus = StatusesStateRemoveStatus
    
    var filters: [(Status) -> Bool] {
        return self.baseFilters + GlobalStore.state.filters.filters.map { $0.filterFunction }
    }
        
    static func reducer(action: Action, state: Self?) -> Self {
        var state = state ?? Self.init()
        
        switch action {
        case let action as SetStatuses: state.updateStatuses(statuses: action.value, withFilters: state.filters)
        case let action as SetPage: (state.nextPage, state.previousPage) = state.paginatingData.updatedPages(pagination: action.value,
                                                                                                             nextPage: state.nextPage,
                                                                                                             previousPage: state.previousPage)
        case let action as PollStatuses: state.pollStatuses(client: action.client)
        case let action as PollOlderStatuses: state.pollStatuses(client: action.client, range: state.nextPage)
        case let action as PollNewerStatuses: state.pollStatuses(client: action.client, range: state.previousPage)
        case let action as UpdateStatus: state.updateStatus(status: action.value)
        case let action as InsertStatus: state.statuses.insert(action.value, at: 0)
        case let action as RemoveStatus: state.removeStatus(status: action.value)
        default: break
        }
        
        return state
    }
    
    func pollStatuses(client: Client, range: RequestRange? = nil) {
        self.paginatingData.pollData(client: client, range: range, existingData: self.statuses, filters: self.baseFilters) { (
            statuses: [Status],
            pagination: Pagination?
        ) in
            DispatchQueue.main.async {
                GlobalStore.dispatch(SetStatuses(value: statuses))
                GlobalStore.dispatch(SetPage(value: pagination))
            }
        }
    }
    
    mutating func updateStatuses(statuses: [Status], withFilters filters: [(Status) -> Bool]) {
        self.baseFilters = filters
        self.statuses = filters.reduce(statuses, { (all, next) in all.filter(next) })
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

struct StatusesStateSetStatuses<State: StateType>: Action { let value: [Status] }
struct StatusesStateSetPage<State: StateType>: Action { let value: Pagination? }
struct StatusesStatePollStatuses<State: StateType>: PollAction { let client: Client }
struct StatusesStatePollOlderStatuses<State: StateType>: PollAction { let client: Client }
struct StatusesStatePollNewerStatuses<State: StateType>: PollAction { let client: Client }
struct StatusesStateUpdateStatus: Action { let value: Status }
struct StatusesStateInsertStatus<State: StateType>: Action { let value: Status }
struct StatusesStateRemoveStatus: Action { let value: Status }

