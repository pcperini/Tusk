//
//  AppState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/11/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import ReSwift

struct AppState: StateType {
    var auth: AuthState
    var timeline: TimelineState
    var notifications: NotificationsState
    
    static func reducer(action: Action, state: AppState?) -> AppState {
        return AppState(
            auth: AuthState.reducer(action: action, state: state?.auth),
            timeline: TimelineState.reducer(action: action, state: state?.timeline),
            notifications: NotificationsState.reducer(action: action, state: state?.notifications)
        )
    }
}

let GlobalStore = Store(reducer: AppState.reducer, state: nil, middleware: [])
