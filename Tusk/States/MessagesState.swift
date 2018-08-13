//
//  MessagesState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/11/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import MastodonKit
import ReSwift

// TODO: Think about how "threading" works here

struct MessagesState: PaginatableState {
    typealias DataType = Status
    
    struct SetStatuses: Action {
        let value: [Status]
        let merge: PaginatingData<Status>.MergeFunction
    }
    private struct SetPage: Action { let value: Pagination? }
    struct PollStatuses: Action { let client: Client }
    struct PollOlderStatuses: Action { let client: Client }
    struct PollNewerStatuses: Action { let client: Client }

    var statuses: [Status] = []
    
    internal var nextPage: RequestRange? = nil
    internal var previousPage: RequestRange? = nil
    internal var paginatingData: PaginatingData<Status> = PaginatingData<Status>()
    
    static func reducer(action: Action, state: MessagesState?) -> MessagesState {
        var state = state ?? MessagesState()
        
        switch action {
        case let action as SetStatuses: state.statuses = action.merge(state.statuses, action.value)
        case let action as SetPage: (state.nextPage, state.previousPage) = state.paginatingData.updatePages(pagination: action.value, state: state)
        case let action as PollStatuses: state.pollStatuses(client: action.client)
        case let action as PollOlderStatuses: state.pollStatuses(client: action.client, range: state.nextPage)
        case let action as PollNewerStatuses: state.pollStatuses(client: action.client, range: state.previousPage)
        default: break
        }
        
        return state
    }
    
    func pollStatuses(client: Client, range: RequestRange? = nil) {
        self.paginatingData.pollData(client: client, range: range, provider: MessagesState.provider) { (
            statuses: [Status],
            pagination: Pagination?,
            merge: @escaping PaginatingData<Status>.MergeFunction
        ) in
            GlobalStore.dispatch(SetStatuses(value: statuses.filter { (status) in status.visibility == .direct }, merge: merge))
            GlobalStore.dispatch(SetPage(value: pagination))
        }
    }
    
    static func provider(range: RequestRange? = nil) -> Request<[Status]> {
        guard let range = range else { return Timelines.home() }
        return Timelines.home(range: range)
    }
}
