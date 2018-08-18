//
//  TimelineState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/11/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import MastodonKit
import ReSwift

struct TimelineState: PaginatableState {
    typealias DataType = Status
    
    struct SetStatuses: Action { let value: [Status] }
    private struct SetPage: Action { let value: Pagination? }
    struct PollStatuses: Action { let client: Client }
    struct PollOlderStatuses: Action { let client: Client }
    struct PollNewerStatuses: Action { let client: Client }
    
    var statuses: [Status] = []
    
    internal var nextPage: RequestRange? = nil
    internal var previousPage: RequestRange? = nil
    internal var paginatingData: PaginatingData<Status> = PaginatingData<Status>()
    
    static func reducer(action: Action, state: TimelineState?) -> TimelineState {
        var state = state ?? TimelineState()
        
        switch action {
        case let action as SetStatuses: state.statuses = action.value
        case let action as SetPage: (state.nextPage, state.previousPage) = state.paginatingData.updatePages(pagination: action.value, state: state)
        case let action as PollStatuses: state.pollStatuses(client: action.client)
        case let action as PollOlderStatuses: state.pollStatuses(client: action.client, range: state.nextPage)
        case let action as PollNewerStatuses: state.pollStatuses(client: action.client, range: state.previousPage)
        default: break
        }
        
        return state
    }
    
    func pollStatuses(client: Client, range: RequestRange? = nil) {
        self.paginatingData.pollData(client: client, range: range, existingData: self.statuses, provider: TimelineState.provider) { (
            statuses: [Status],
            pagination: Pagination?
        ) in
            GlobalStore.dispatch(SetStatuses(value: statuses.filter { (status) in
                status.visibility != .direct
            }))
            GlobalStore.dispatch(SetPage(value: pagination))
        }
    }
    
    static func provider(range: RequestRange? = nil) -> Request<[Status]> {
        guard let range = range else { return Timelines.home(range: .limit(40)) }
        return Timelines.home(range: range)
    }
}
