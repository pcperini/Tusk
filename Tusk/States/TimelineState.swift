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
    struct SetStatuses: Action { let value: [Status] }
    struct PollStatuses: Action {
        let client: Client
        let timeline: Timeline
    }
    
    enum Timeline {
        case Home
        case Public
        case Tag(String)
        case Account(String)
    }
    
    var statuses: [Status] = []
    
    static func reducer(action: Action, state: TimelineState?) -> TimelineState {
        var state = state ?? TimelineState()
        
        switch action {
        case let action as SetStatuses: state.statuses = action.value
        case let action as PollStatuses: pollStatuses(client: action.client, timeline: action.timeline)
        default: break
        }
        
        return state
    }
    
    static func pollStatuses(client: Client, timeline: Timeline) {
        let request: Request<[Status]>
        switch timeline {
        case .Home: request = Timelines.home()
        case .Public: request = Timelines.public()
        case .Tag(let tag): request = Timelines.tag(tag)
        case .Account(let id): request = Accounts.statuses(id: id)
        }
        
        client.run(request) { (result) in
            switch result {
            case .success(let statuses, _): GlobalStore.dispatch(SetStatuses(value: statuses))
            default: break
            }
        }
    }
}
