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
    struct PollHashtag: Action { let client: Client; let value: String }
    struct SetSearchResults: Action { let term: String; let value: Results }
    
    private var results: [String: Results] = [:]
    private(set) var activeHashtag: HashtagState? = nil
    
    static func reducer(action: Action, state: SearchState?) -> SearchState {
        var state = state ?? SearchState()
        
        switch action {
        case let action as PollSearch: state.pollSearch(client: action.client, term: action.value)
        case let action as SetSearchResults: state.results[action.term] = action.value
        case let action as PollHashtag: state.pollHashtag(client: action.client, hashtag: action.value)
        default: state.passThroughReducer(action: action, state: state)
        }
        
        return state
    }
    
    private mutating func passThroughReducer(action: Action, state: SearchState) {
        if let hashtag = self.activeHashtag {
            self.activeHashtag = HashtagState.reducer(action: action, state: hashtag)
        }
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
    
    mutating func pollHashtag(client: Client, hashtag: String) {
        var state = HashtagState()
        state.hashtag = hashtag
        self.activeHashtag = HashtagState.reducer(action: HashtagState.PollStatuses(client: client), state: state)
    }
}
