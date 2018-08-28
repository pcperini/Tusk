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
    
    let status: Status
    var context: Context?
    var statuses: [Status] {
        get {
            guard let context = self.context else { return [self.status] }
            return context.ancestors + [self.status] + context.descendants
        }
        set {}
    }
    
    static func reducer(action: Action, state: ContextState?) -> ContextState {
        var state = state
        
        switch action {
        case let action as SetContext: state?.context = action.value
        case let action as PollContext: do {
            state = ContextState(status: action.status, context: nil)
            state?.pollContext(client: action.client)
            }
        default: break
        }
        
        return state!
    }
    
    func pollContext(client: Client) {
        let request = Statuses.context(id: self.status.id)
        client.run(request) { (result) in
            switch result {
            case .success(let resp, _): do {
                GlobalStore.dispatch(SetContext(value: resp))
                log.verbose("success \(request)", context: ["resp": resp])
                }
            case .failure(let error): log.error("error \(request)", context: ["err": error])
            }
        }
    }
}
