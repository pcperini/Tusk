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
    
    static var additionalReducer: ((Action, Self?) -> Self)? { get }
    
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
    typealias UpdateStatus = StatusesStateUpdateStatus
        
    static func reducer(action: Action, state: Self?) -> Self {
        var state = state ?? Self.init()
        
        switch action {
        case let action as SetFilters: state.filters = action.value
        case let action as SetStatuses: state.statuses = action.value
        case let action as SetPage: (state.nextPage, state.previousPage) = state.paginatingData.updatedPages(pagination: action.value,
                                                                                                             nextPage: state.nextPage,
                                                                                                             previousPage: state.previousPage)
        case let action as PollStatuses: state.pollStatuses(client: action.client)
        case let action as PollOlderStatuses: state.pollStatuses(client: action.client, range: state.nextPage)
        case let action as PollNewerStatuses: state.pollStatuses(client: action.client, range: state.previousPage)
        case let action as UpdateStatus: state.updateStatus(status: action.value)
        default: break
        }
        
        state = self.additionalReducer?(action, state) ?? state
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
    
    mutating func updateStatus(status: Status) {
        if let index = self.statuses.index(where: { $0.id == status.id }) {
            self.statuses[index] = status
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
struct StatusesStateUpdateStatus: Action { let value: Status }
