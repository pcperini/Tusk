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

struct MessagesState: StateType {
    struct SetStatuses: Action { let value: [Status] }
    struct PollStatuses: Action { let client: Client }

    var statuses: [Status] = []
    
    static func reducer(action: Action, state: MessagesState?) -> MessagesState {
        var state = state ?? MessagesState()
        
        switch action {
        case let action as SetStatuses: state.statuses = action.value
        case let action as PollStatuses: pollStatuses(client: action.client)
        default: break
        }
        
        return state
    }
    
    static func pollStatuses(client: Client) {
        let request = Timelines.home()
        client.run(request) { (result) in
            switch result {
            case .success(let statuses, _): GlobalStore.dispatch(SetStatuses(value: statuses.filter { (status) in
                status.visibility == .direct
            }))
            default: break
            }
        }
    }
}
