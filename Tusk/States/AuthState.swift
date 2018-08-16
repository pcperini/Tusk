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
    struct PollAccessToken: Action { let code: String }
    
    static let defaultInstance: String = "mastodon.social"
    
    var instance: String? = nil
    var accessToken: String?
    var code: String?
    var client: Client?
    
    var baseURL: String? {
        guard let instance = self.instance else { return nil }
        return "https://\(instance)"
    }
    
    static func reducer(action: Action, state: AuthState?) -> AuthState {
        let oldInstance = state?.instance
        var state = state ?? AuthState()
        
        switch action {
        case let action as SetInstance: state.instance = action.value
        case let action as SetAccessToken: state.accessToken = action.value
        case let action as PollAccessToken: do {
            state.code = action.code
            pollAccessToken(client: state.client, code: action.code)
            }
        default: break
        }
        
        if (oldInstance != state.instance) {
            if let url = state.baseURL {
                state.client = Client(baseURL: url)
            } else {
                state.client = nil
            }
        }
        
        if (state.client?.accessToken != state.accessToken) {
            state.client?.accessToken = state.accessToken
        }
        
        return state
    }
    
    static func pollAccessToken(client: Client?, code: String) {
        guard let client = client else { return }
        let request = Login.oauth(clientID: "8d378392a7320d1c24b69bf7b908d91fadc91634996b5afaed9aad6a03c284ef",
                                  clientSecret: "a00962b37dfc52c662f0b618e7c6ab16509d5b55b74135352fa1edb9720a5f5d",
                                  code: code,
                                  redirectURI: "tusk://oauth")
        client.run(request) { (result) in
            switch result {
            case .success(let resp, _): do {
                GlobalStore.dispatch(SetAccessToken(value: resp.accessToken))
                GlobalStore.dispatch(AppState.PollData())
                }
            case .failure(let error): print(error, #file, #line)
            }
        }
    }
}
