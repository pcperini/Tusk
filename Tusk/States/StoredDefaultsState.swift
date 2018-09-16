//
//  StoredDefaultsState.swift
//  Tusk
//
//  Created by Patrick Perini on 9/16/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import ReSwift

struct StoredDefaultsState: StateType {
    struct LoadDefaults: Action {}
    struct AddUnsuppressedStatusID: Action { let value: String }
    
    var unsuppressedStatusIDs: [String] = []
    
    static func reducer(action: Action, state: StoredDefaultsState?) -> StoredDefaultsState {
        var state = state ?? StoredDefaultsState()
        
        switch action {
        case is LoadDefaults: state.load()
        case let action as AddUnsuppressedStatusID: state.addUnsuppressedStatusID(id: action.value)
        default: break
        }
        
        return state
    }
    
    mutating func load() {
        self.unsuppressedStatusIDs = Array(
            (NSUbiquitousKeyValueStore.default.dictionary(forKey: "UnsuppressedStatusIDs") as? [String: Date] ?? [:])
                .filter({ Date().timeIntervalSince($0.value) <= 24 * 60 * 60 })
                .keys
        )
    }
    
    mutating func addUnsuppressedStatusID(id: String) {
        guard self.unsuppressedStatusIDs.index(of: id) == nil else { return }
        
        var stored = NSUbiquitousKeyValueStore.default.dictionary(forKey: "UnsuppressedStatusIDs") as? [String: Date] ?? [:]
            .filter({ Date().timeIntervalSince($0.value) <= 24 * 60 * 60 })
        
        guard stored.keys.index(of: id) == nil else { return }
        
        stored[id] = Date()
        self.unsuppressedStatusIDs = Array(stored.keys)
        
        NSUbiquitousKeyValueStore.default.set(stored, forKey: "UnsuppressedStatusIDs")
        NSUbiquitousKeyValueStore.default.synchronize()
    }
}
