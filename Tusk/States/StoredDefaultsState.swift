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
    struct SetLastSeenID: Action { let context: String; let value: String }
    struct SetLoadFromLastSeen: Action { let value: Bool }
    
    var unsuppressedStatusIDs: [String] = []
    var hideContentWarnings: Bool = true
    var defaultStatusVisibility: Visibility = .public
    private var lastSeenIDs: [String: String] = [:]
    var loadFromLastSeen: Bool = true
    
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
        case let action as SetLastSeenID: do {
            state.lastSeenIDs[action.context] = action.value
            state.save(value: state.lastSeenIDs, forKey: "LastSeenIDs")
            }
        case let action as SetLoadFromLastSeen: do {
            state.loadFromLastSeen = action.value
            state.save(value: action.value, forKey: "LoadFromLastSeen")
            }
        default: break
        }
        
        return state
    }
    
    mutating func load() {
        self.unsuppressedStatusIDs = Array(
            (self.load(type: [String: Date].self, key: "UnsuppressedStatusIDs") ?? [:])
                .filter({ Date().timeIntervalSince($0.value) <= 24 * 60 * 60 })
                .keys
        )
        
        if let hideCW = self.load(type: Bool.self, key: "HideContentWarnings") {
            self.hideContentWarnings = hideCW
        }
        if let rawVis = self.load(type: String.self, key: "DefaultStatusVisibility"),
            let vis = Visibility(rawValue: rawVis) {
            self.defaultStatusVisibility = vis
        }
        
        self.lastSeenIDs = self.load(type: [String: String].self, key: "LastSeenIDs") ?? [:]
        self.loadFromLastSeen = self.load(type: Bool.self, key: "LoadFromLastSeen") ?? true
    }
    
    func lastSeenID(forContext context: String) -> String? {
        guard self.loadFromLastSeen else { return nil }
        return self.lastSeenIDs[context]
    }
    
    func load<T>(type: T.Type, key: String) -> T? {
        guard let value = NSUbiquitousKeyValueStore.default.object(forKey: key) as? T else { return nil }
        return value
    }
    
    func save(value: Any, forKey key: String) {
        NSUbiquitousKeyValueStore.default.set(value, forKey: key)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    mutating func addUnsuppressedStatusID(id: String) {
        guard self.unsuppressedStatusIDs.index(of: id) == nil else { return }
        
        var stored = self.load(type: [String: Date].self, key: "UnsuppressedStatusIDs") ?? [:]
            .filter({ Date().timeIntervalSince($0.value) <= 24 * 60 * 60 })
        
        guard stored.keys.index(of: id) == nil else { return }
        
        stored[id] = Date()
        self.unsuppressedStatusIDs = Array(stored.keys)
        
        self.save(value: stored, forKey: "UnsuppressedStatusIDs")
    }
}
