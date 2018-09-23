//
//  FiltersState.swift
//  Tusk
//
//  Created by Patrick Perini on 9/21/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import MastodonKit
import ReSwift

struct FiltersState: StateType {
    struct PollFilters: Action { let client: Client }
    struct SetFilters: Action { let value: [Filter] }
    
    private(set) var filters: [Filter] = []
    
    static func reducer(action: Action, state: FiltersState?) -> FiltersState {
        var state = state ?? FiltersState()
        
        switch action {
        case let action as PollFilters: state.pollFilters(client: action.client)
        case let action as SetFilters: state.filters = action.value
        default: break
        }
        
        return state
    }
    
    func pollFilters(client: Client) {
        let request = Filters.all()
        client.run(request: request, success: { (resp, _) in
            GlobalStore.dispatch(SetFilters(value: resp))
        })
    }
}
