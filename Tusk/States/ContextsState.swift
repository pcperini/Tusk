//
//  ContextsState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/23/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import MastodonKit
import ReSwift

struct ContextsState: StateType {
    private var allContexts: [ContextState] = []
    
    static func reducer(action: Action, state: ContextsState?) -> ContextsState {
        var state = state ?? ContextsState()
        
        switch action {
        case let action as ContextState.PollContext: state.allContexts += [ContextState.reducer(action: action, state: nil)]
        default: state.allContexts = self.passThroughReducer(action: action, state: state)
        }
        
        return state
    }
    
    private static func passThroughReducer(action: Action, state: ContextsState) -> [ContextState] {
        return state.allContexts.map({ (context) in ContextState.reducer(action: action, state: context) })
            .dedupe(on: { (context) in context.status?.id ?? "" })
    }
    
    func contextForStatusWithID(id: String) -> ContextState? {
        return self.allContexts.first(where: { (context) in context.status?.id == id })
    }
}
