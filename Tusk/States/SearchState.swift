//
//  SearchState.swift
//  Tusk
//
//  Created by Patrick Perini on 9/26/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import MastodonKit
import ReSwift

struct SearchState: StateType {
    struct PollSearch: Action { let client: Client; let value: String }
    struct SetSearchResults: Action { let term: String; let value: Results }
    
    private var results: [String: Results] = [:]
    
    static func reducer(action: Action, state: SearchState?) -> SearchState {
        var state = state ?? SearchState()
        
        switch action {
        case let action as PollSearch: state.pollSearch(client: action.client, term: action.value)
        case let action as SetSearchResults: state.results[action.term] = action.value
        default: break
        }
        
        return state
    }
    
    func results(forTerm term: String) -> ([Account], [Status], [String]) {
        guard let results = self.results[term] else { return ([], [], []) }
        return (results.accounts, results.statuses, results.hashtags)
    }
    
    func pollSearch(client: Client, term: String) {
        let request = Search.search(query: term, resolve: true)
        client.run(request: request, success: { (resp, _) in
            GlobalStore.dispatch(SetSearchResults(term: term, value: resp))
        })
    }
}
