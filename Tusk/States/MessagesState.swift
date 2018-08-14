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
// TODO: ForceOlderStatuses is a hack, think about filling out pages

struct MessagesState: PaginatableState {
    typealias DataType = Status
    
    struct SetStatuses: Action {
        let value: [Status]
        let merge: PaginatingData<Status>.MergeFunction
    }
    private struct SetPage: Action { let value: Pagination? }
    struct PollStatuses: Action { let client: Client }
    struct PollNewerStatuses: Action { let client: Client }
    struct PollOlderStatuses: Action { let client: Client }
    private struct ForceOlderStatuses: Action { let client: Client }

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
        case let action as ForceOlderStatuses: state.pollStatuses(client: action.client, range: state.nextPage, override: state.statuses.isEmpty)
        default: break
        }
        
        return state
    }
    
    func pollStatuses(client: Client, range: RequestRange? = nil, override: Bool = false) {
        self.paginatingData.pollData(client: client, range: range, provider: MessagesState.provider) { (
            statuses: [Status],
            pagination: Pagination?,
            merge: @escaping PaginatingData<Status>.MergeFunction
        ) in
            let filtered = statuses.filter { (status) in
                status.visibility == .direct && status.account != GlobalStore.state.account.account
            }
            let merge = override ? { (old, new) in return new } : merge
            
            GlobalStore.dispatch(SetStatuses(value: filtered, merge: merge))
            GlobalStore.dispatch(SetPage(value: pagination))
            
            if (filtered.count < 1) {
                GlobalStore.dispatch(ForceOlderStatuses(client: client))
            }
        }
    }
    
    static func provider(range: RequestRange? = nil) -> Request<[Status]> {
        guard let range = range else { return Timelines.home() }
        return Timelines.home(range: range)
    }
}
