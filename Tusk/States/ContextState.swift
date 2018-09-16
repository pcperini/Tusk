//
//  ContextState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/23/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import MastodonKit
import ReSwift

protocol ContextAction: Action { var status: Status { get } }

struct ContextState: StateType, StatusViewableState {
    struct SetContext: ContextAction { let value: Context?; let status: Status }
    struct PollContext: ContextAction, PollAction { let client: Client; let status: Status }
    
    var status: Status? = nil
    var statuses: [Status] = []

    var context: Context? {
        didSet {
            self.statuses = []
            if let context = self.context {
                self.statuses = context.ancestors + [self.status].compactMap({ $0 }) + context.descendants
            }
        }
    }
    
    static func reducer(action: Action, state: ContextState?) -> ContextState {
        var state = state ?? ContextState()
        switch action {
        case let action as StatusesState.UpdateStatus: do {
            state.updateStatus(status: action.value)
            }
        default: break
        }
        
        guard let action = action as? ContextAction else { return state }
        
        switch action {
        case let action as PollContext: do {
            state = ContextState(status: action.status, statuses: [], context: nil)
            state.pollContext(client: action.client)
            }
        default: break
        }
        
        guard action.status == state.status else { return state }
        
        switch action {
        case let action as SetContext: state.context = action.value
        default: break
        }
        
        return state
    }
    
    mutating func updateStatus(status: Status) {
        if let index = self.statuses.index(of: status) {
            self.statuses[index] = status
        }
    }
    
    func pollContext(client: Client) {
        guard let status = self.status else { return }
        let request = Statuses.context(id: status.id)
        client.run(request: request, success: { (resp, _) in
            GlobalStore.dispatch(SetContext(value: resp, status: status))
        })
    }
}
