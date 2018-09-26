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
    struct Init: Action {}
    struct PurgeMemory: Action {} // TODO: Implement
    struct PollData: Action {}
    
    var auth: AuthState
    var timeline: TimelineState
    var mentions: MentionsState
    var notifications: NotificationsState
    var messages: MessagesState
    var filters: FiltersState
    var favourites: FavouritesState
    var accounts: AccountsState
    var contexts: ContextsState
    var search: SearchState
    
    var statusUpdates: StatusUpdateState
    var errors: ErrorsState
    var storedDefaults: StoredDefaultsState
    
    static func reducer(action: Action, state: AppState?) -> AppState {
        switch action {
        case is PollData: state?.pollData()
        default: break
        }

        return AppState(
            auth: AuthState.reducer(action: action, state: state?.auth),
            timeline: TimelineState.reducer(action: action, state: state?.timeline),
            mentions: MentionsState.reducer(action: action, state: state?.mentions),
            notifications: NotificationsState.reducer(action: action, state: state?.notifications),
            messages: MessagesState.reducer(action: action, state: state?.messages),
            filters: FiltersState.reducer(action: action, state: state?.filters),
            favourites: FavouritesState.reducer(action: action, state: state?.favourites),
            accounts: AccountsState.reducer(action: action, state: state?.accounts),
            contexts: ContextsState.reducer(action: action, state: state?.contexts),
            search: SearchState.reducer(action: action, state: state?.search),
            
            statusUpdates: StatusUpdateState.reducer(action: action, state: state?.statusUpdates),
            errors: ErrorsState.reducer(action: action, state: state?.errors),
            storedDefaults: StoredDefaultsState.reducer(action: action, state: state?.storedDefaults)
        )
    }
    
    func pollData() {
        guard let client = self.auth.client else { return }
        DispatchQueue.main.async {
            GlobalStore.dispatch(TimelineState.PollStatuses(client: client))
            GlobalStore.dispatch(MentionsState.PollStatuses(client: client))
            GlobalStore.dispatch(MessagesState.PollStatuses(client: client))
            GlobalStore.dispatch(FiltersState.PollFilters(client: client))
            GlobalStore.dispatch(NotificationsState.PollNotifications(client: client))
            GlobalStore.dispatch(AccountState.PollAccount(client: client, account: nil))
            GlobalStore.dispatch(StoredDefaultsState.LoadDefaults())
        }
    }
    
    static func handleURL(url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
        guard let host = urlComponents.host else { return false }
        
        switch host {
        case "oauth": do {
            guard let code = urlComponents.queryItems?.first(where: { (queryItem) in queryItem.name == "code" })?.value else { return false }
            GlobalStore.dispatch(AuthState.PollAccessToken(code: code))
            }
        default: return false
        }
        
        return true
    }
}

let GlobalStore = Store(reducer: AppState.reducer, state: nil, middleware: [])
