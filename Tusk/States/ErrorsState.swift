//
//  ErrorsState.swift
//  Tusk
//
//  Created by Patrick Perini on 9/2/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import ReSwift

struct ErrorsState: StateType {
    struct AddError: Action { let value: Error }
    
    var errors: [(Error, Date)] = []
    
    static func reducer(action: Action, state: ErrorsState?) -> ErrorsState {
        var state = state ?? ErrorsState()
        
        switch action {
        case let action as AddError: state.errors.append((action.value, Date()))
        default: break
        }
        
        return state
    }
}
