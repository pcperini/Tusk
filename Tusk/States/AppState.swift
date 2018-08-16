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
    var notifications: NotificationsState
    var messages: MessagesState
    var account: AccountState
    
    static func reducer(action: Action, state: AppState?) -> AppState {
        switch action {
        case _ as PollData: state?.pollData()
        default: break
        }
        
        return AppState(
            auth: AuthState.reducer(action: action, state: state?.auth),
            timeline: TimelineState.reducer(action: action, state: state?.timeline),
            notifications: NotificationsState.reducer(action: action, state: state?.notifications),
            messages: MessagesState.reducer(action: action, state: state?.messages),
            account: AccountState.reducer(action: action, state: state?.account)
        )
    }
    
    func pollData() {
        guard let client = self.auth.client else { return }
        DispatchQueue.global(qos: .background).async {
            GlobalStore.dispatch(TimelineState.PollStatuses(client: client))
            GlobalStore.dispatch(MessagesState.PollStatuses(client: client))
            GlobalStore.dispatch(NotificationsState.PollNotifications(client: client))
            GlobalStore.dispatch(AccountState.PollActiveAccount(client: client))
        }
    }
}

let GlobalStore = Store(reducer: AppState.reducer, state: nil, middleware: [])
