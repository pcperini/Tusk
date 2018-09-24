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
    struct SaveFilter: Action { let client: Client; let phrase: String; let id: Int? }
    struct DeleteFilter: Action { let client: Client; let id: Int }
    
    private(set) var filters: [Filter] = []
    
    static func reducer(action: Action, state: FiltersState?) -> FiltersState {
        var state = state ?? FiltersState()
        
        switch action {
        case let action as PollFilters: state.pollFilters(client: action.client)
        case let action as SetFilters: state.filters = action.value
        case let action as SaveFilter: state.saveFilter(client: action.client,
                                                        phrase: action.phrase,
                                                        id: action.id)
        case let action as DeleteFilter: state.deleteFilter(client: action.client, id: action.id)
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
    
    func saveFilter(client: Client, phrase: String, id: Int?) {
        let request = Filters.save(id: id, phrase: phrase, contexts: ["home"])
        client.run(request: request, success: { (resp, _) in
            var filters = self.filters
            if let index = filters.firstIndex(of: resp) {
                filters[index] = resp
            } else {
                filters = [resp] + filters
            }

            GlobalStore.dispatch(SetFilters(value: filters))
        })
    }
    
    func deleteFilter(client: Client, id: Int) {
        let request = Filters.delete(id: id)
        client.run(request: request, success: { (resp, _) in
            let filters = self.filters.filter({ $0.id != id})
            GlobalStore.dispatch(SetFilters(value: filters))
        })
    }
}
