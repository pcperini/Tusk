//
//  ContextState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/23/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import MastodonKit
import ReSwift

struct ContextState: StateType, StatusViewableState {
    struct SetContext: Action { let value: Context? }
    struct PollContext: PollAction { let client: Client; let status: Status }
    
    var status: Status
    var statuses: [Status] = []
    var unsuppressedStatusIDs: [String] = []
    var context: Context? {
        didSet {
            self.statuses = []
            if let context = self.context {
                self.statuses = context.ancestors + [self.status] + context.descendants
            }
        }
    }
    
    static func reducer(action: Action, state: ContextState?) -> ContextState {
        var state = state
        
        switch action {
        case let action as SetContext: state?.context = action.value
        case let action as PollContext: do {
            state = ContextState(status: action.status, statuses: [], unsuppressedStatusIDs: [], context: nil)
            state?.pollContext(client: action.client)
            }
        case let action as StatusesState.UpdateStatus: do {
            state?.updateStatus(status: action.value)
            }
        default: break
        }
        
        return state!
    }
    
    mutating func updateStatus(status: Status) {
        if let index = self.statuses.index(of: status) {
            self.statuses[index] = status
        }
    }
    
    func pollContext(client: Client) {
        let request = Statuses.context(id: self.status.id)
        client.run(request: request, success: { (resp, _) in
            GlobalStore.dispatch(SetContext(value: resp))
        })
    }
}
