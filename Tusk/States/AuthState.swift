//
//  AuthState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/11/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import MastodonKit
import ReSwift

struct AuthState: StateType {
    struct SetInstance: Action { let value: String }
    struct SetAccessToken: Action { let value: String? }
    
    static let defaultInstance: String = "mastodon.social"
    
    var instance: String = defaultInstance
    var accessToken: String?
    var client: Client?
    
    static func reducer(action: Action, state: AuthState?) -> AuthState {
        let oldInstance = state?.instance
        var state = state ?? AuthState()
        
        switch action {
        case let action as SetInstance: state.instance = action.value
        case let action as SetAccessToken: state.accessToken = action.value
        default: break
        }
        
        if (oldInstance != state.instance) {
            state.client = Client(baseURL: "https://\(state.instance)")
        }
        
        if (state.client?.accessToken != state.accessToken) {
            state.client?.accessToken = state.accessToken
        }
        
        print(state)
        return state
    }
}
