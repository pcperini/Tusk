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
    var filters: [(Status) -> Bool] { get set }
    
    init()
    func pollStatuses(client: Client, range: RequestRange?)
    mutating func updateStatus(status: Status)
}

extension StatusesState {
    typealias SetFilters = StatusesStateSetFilters<Self>
    typealias SetStatuses = StatusesStateSetStatuses<Self>
    typealias SetPage = StatusesStateSetPage<Self>
    typealias PollStatuses = StatusesStatePollStatuses<Self>
    typealias PollOlderStatuses = StatusesStatePollOlderStatuses<Self>
    typealias PollNewerStatuses = StatusesStatePollNewerStatuses<Self>
    typealias PollFilters = StatusesStatePollFilters
    typealias UpdateStatus = StatusesStateUpdateStatus
    typealias InsertStatus = StatusesStateInsertStatus<Self>
        
    static func reducer(action: Action, state: Self?) -> Self {
        var state = state ?? Self.init()
        
        switch action {
        case let action as SetFilters: state.updateStatuses(statuses: state.statuses, withFilters: action.value)
        case let action as SetStatuses: state.updateStatuses(statuses: action.value, withFilters: state.filters)
        case let action as SetPage: (state.nextPage, state.previousPage) = state.paginatingData.updatedPages(pagination: action.value,
                                                                                                             nextPage: state.nextPage,
                                                                                                             previousPage: state.previousPage)
        case let action as PollStatuses: state.pollStatuses(client: action.client)
        case let action as PollOlderStatuses: state.pollStatuses(client: action.client, range: state.nextPage)
        case let action as PollNewerStatuses: state.pollStatuses(client: action.client, range: state.previousPage)
        case let action as PollFilters: state.pollFilters(client: action.client)
        case let action as UpdateStatus: state.updateStatus(status: action.value)
        case let action as InsertStatus: state.statuses.insert(action.value, at: 0)
        default: break
        }
        
        return state
    }
    
    func pollStatuses(client: Client, range: RequestRange? = nil) {
        self.paginatingData.pollData(client: client, range: range, existingData: self.statuses, filters: self.filters) { (
            statuses: [Status],
            pagination: Pagination?
        ) in
            GlobalStore.dispatch(SetStatuses(value: statuses))
            GlobalStore.dispatch(SetPage(value: pagination))
        }
    }
    
    func pollFilters(client: Client) {
        let request = Filters.all()
        client.run(request) { (result) in
            switch result {
            case .success(let resp, _): do {
                log.verbose("success \(request)", context: ["resp": resp])
                GlobalStore.dispatch(SetFilters(value: self.filters + resp.map { $0.filterFunction }))
                }
            case .failure(let error): log.error("error \(request) 🚨 Error: \(error)\n")
            }
        }
    }
    
    mutating func updateStatuses(statuses: [Status], withFilters filters: [(Status) -> Bool]) {
        self.filters = filters
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
}

struct StatusesStateSetFilters<State: StateType>: Action { let value: [(Status) -> Bool] }
struct StatusesStateSetStatuses<State: StateType>: Action { let value: [Status] }
struct StatusesStateSetPage<State: StateType>: Action { let value: Pagination? }
struct StatusesStatePollStatuses<State: StateType>: PollAction { let client: Client }
struct StatusesStatePollOlderStatuses<State: StateType>: PollAction { let client: Client }
struct StatusesStatePollNewerStatuses<State: StateType>: PollAction { let client: Client }
struct StatusesStatePollFilters: PollAction { let client: Client }
struct StatusesStateUpdateStatus: Action { let value: Status }
struct StatusesStateInsertStatus<State: StateType>: Action { let value: Status }
