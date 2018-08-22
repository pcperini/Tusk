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

protocol StatusesState: PaginatableState where DataType == Status {
    associatedtype SetFilters: Action
    associatedtype SetStatuses: Action
    associatedtype SetPage: Action
    associatedtype PollStatuses: Action
    associatedtype PollOlderStatuses: Action
    associatedtype PollNewerStatuses: Action
    
    var statuses: [Status] { get set }
    var filters: [(Status) -> Bool] { get set }
    
    init()
    func pollStatuses(client: Client, range: RequestRange?)
}

extension StatusesState {
    typealias SetFilters = StatusesStateSetFilters<Self>
    typealias SetStatuses = StatusesStateSetStatuses<Self>
    typealias SetPage = StatusesStateSetPage<Self>
    typealias PollStatuses = StatusesStatePollStatuses<Self>
    typealias PollOlderStatuses = StatusesStatePollOlderStatuses<Self>
    typealias PollNewerStatuses = StatusesStatePollNewerStatuses<Self>
        
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
}

struct StatusesStateSetFilters<State: StateType>: Action { let value: [(Status) -> Bool] }
struct StatusesStateSetStatuses<State: StateType>: Action { let value: [Status] }
struct StatusesStateSetPage<State: StateType>: Action { let value: Pagination? }
struct StatusesStatePollStatuses<State: StateType>: Action { let client: Client }
struct StatusesStatePollOlderStatuses<State: StateType>: Action { let client: Client }
struct StatusesStatePollNewerStatuses<State: StateType>: Action { let client: Client }
