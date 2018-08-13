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

struct TimelineState: StateType {
    struct SetStatuses: Action {
        let value: [Status]
        let merge: ([Status], [Status]) -> [Status]
    }
    private struct SetPage: Action { let value: Pagination? }
    struct PollStatuses: Action { let client: Client }
    struct PollEarlierStatuses: Action { let client: Client }
    
    var statuses: [Status] = []
    private var nextPage: RequestRange? // EARLIER statuses, the "next page" in reverse chronological order
    private var previousPage: RequestRange? // LATER statuses, the "prev page" in reverse chronological order
    
    static func reducer(action: Action, state: TimelineState?) -> TimelineState {
        var state = state ?? TimelineState()
        
        switch action {
        case let action as SetStatuses: state.statuses = action.merge(state.statuses, action.value)
        case let action as SetPage: (state.nextPage, state.previousPage) = updatePages(pagination: action.value, state: state)
        case let action as PollStatuses: pollStatuses(client: action.client)
        case let action as PollEarlierStatuses: pollStatuses(client: action.client, range: state.nextPage)
        default: break
        }
        
        return state
    }
    
    static func pollStatuses(client: Client, range: RequestRange? = nil) {
        let request: Request<[Status]>
        let merge: ([Status], [Status]) -> [Status]
        
        if let range = range {
            request = Timelines.home(range: range)
            switch range {
            case .since(_, _): merge = { (old, new) in new + old }
            case .max(_, _): merge = { (old, new) in old + new }
            default: merge = { (old, new) in new }
            }
        }
        else {
            request = Timelines.home()
            merge = { (old, new) in new }
        }
        
        client.run(request) { (result) in
            switch result {
            case .success(let statuses, let pagination): do {
                GlobalStore.dispatch(SetStatuses(value: statuses.filter { (status) in status.visibility != .direct }, merge: merge))
                GlobalStore.dispatch(SetPage(value: pagination))
            }
            default: break
            }
        }
    }
    
    static func updatePages(pagination: Pagination?, state: TimelineState) -> (RequestRange?, RequestRange?) {
        // some shit in here
        print(pagination)
        
        guard let oldNext = state.nextPage, let oldPrev = state.previousPage else { return (pagination?.next, pagination?.previous) }
        guard let newNext = pagination?.next, let newPrev = pagination?.previous else { return (state.nextPage, state.previousPage) }

        let setNext: RequestRange? = newNext < oldNext ? newNext : oldNext
        let setPrev: RequestRange? = newPrev > oldPrev ? newPrev : oldPrev
        
        print(setNext, setPrev)
        return (setNext, setPrev)
    }
}
