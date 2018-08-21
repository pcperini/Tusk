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
    struct PollData: Action {}
    
    var auth: AuthState
    var timeline: TimelineState
    var mentions: MentionsState
    var notifications: NotificationsState
    var messages: MessagesState
    var account: AccountsState
    
    static func reducer(action: Action, state: AppState?) -> AppState {
        switch action {
        case _ as PollData: state?.pollData()
        default: break
        }
        
        return AppState(
            auth: AuthState.reducer(action: action, state: state?.auth),
            timeline: TimelineState.reducer(action: action, state: state?.timeline),
            mentions: MentionsState.reducer(action: action, state: state?.mentions),
            notifications: NotificationsState.reducer(action: action, state: state?.notifications),
            messages: MessagesState.reducer(action: action, state: state?.messages),
            account: AccountsState.reducer(action: action, state: state?.account)
        )
    }
    
    func pollData() {
        guard let client = self.auth.client else { return }
        DispatchQueue.main.async {
            GlobalStore.dispatch(TimelineState.PollStatuses(client: client))
            GlobalStore.dispatch(MentionsState.PollStatuses(client: client))
            GlobalStore.dispatch(MessagesState.PollStatuses(client: client))
            GlobalStore.dispatch(NotificationsState.PollNotifications(client: client))
            GlobalStore.dispatch(AccountsState.PollActiveAccount(client: client))
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
