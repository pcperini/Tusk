//
//  StoredDefaultsState.swift
//  Tusk
//
//  Created by Patrick Perini on 9/16/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import ReSwift
import MastodonKit

struct StoredDefaultsState: StateType {
    struct LoadDefaults: Action {}
    struct AddUnsuppressedStatusID: Action { let value: String }
    struct SetHideContentWarnings: Action { let value: Bool }
    struct SetDefaultPostVisibility: Action { let value: Visibility }
    
    var unsuppressedStatusIDs: [String] = []
    var hideContentWarnings: Bool = true
    var defaultStatusVisibility: Visibility = .public
    
    static func reducer(action: Action, state: StoredDefaultsState?) -> StoredDefaultsState {
        var state = state ?? StoredDefaultsState()
        
        switch action {
        case is LoadDefaults: state.load()
        case let action as AddUnsuppressedStatusID: state.addUnsuppressedStatusID(id: action.value)
        case let action as SetHideContentWarnings: do {
            state.hideContentWarnings = action.value
            state.save(value: action.value, forKey: "HideContentWarnings")
            }
        case let action as SetDefaultPostVisibility: do {
            state.defaultStatusVisibility = action.value
            state.save(value: action.value.rawValue, forKey: "DefaultStatusVisibility")
            }
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
        
        self.hideContentWarnings = NSUbiquitousKeyValueStore.default.bool(forKey: "HideContentWarnings")
        if let vis = Visibility(rawValue: NSUbiquitousKeyValueStore.default.string(forKey: "DefaultStatusVisibility") ?? "") {
            self.defaultStatusVisibility = vis
        }
    }
    
    func save(value: Any, forKey key: String) {
        NSUbiquitousKeyValueStore.default.set(value, forKey: key)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    mutating func addUnsuppressedStatusID(id: String) {
        guard self.unsuppressedStatusIDs.index(of: id) == nil else { return }
        
        var stored = NSUbiquitousKeyValueStore.default.dictionary(forKey: "UnsuppressedStatusIDs") as? [String: Date] ?? [:]
            .filter({ Date().timeIntervalSince($0.value) <= 24 * 60 * 60 })
        
        guard stored.keys.index(of: id) == nil else { return }
        
        stored[id] = Date()
        self.unsuppressedStatusIDs = Array(stored.keys)
        
        self.save(value: stored, forKey: "UnsuppressedStatusIDs")
    }
}
