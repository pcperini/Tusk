//
//  TimelineState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/11/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import MastodonKit
import ReSwift

typealias MastodonNotification = MastodonKit.Notification // overloaded with UIKit.Notification

struct NotificationsState: StateType {
    struct SetNotifications: Action { let value: [MastodonNotification] }
    struct PollNotifications: Action { let client: Client }
    
    var statuses: [MastodonNotification] = []
    
    static func reducer(action: Action, state: NotificationsState?) -> NotificationsState {
        var state = state ?? NotificationsState()
        
        switch action {
        case let action as SetNotifications: state.statuses = action.value
        case let action as PollNotifications: pollNotifications(client: action.client)
        default: break
        }
        
        return state
    }
    
    static func pollNotifications(client: Client) {
        let request: Request<[MastodonNotification]> = Notifications.all()
        client.run(request) { (result) in
            switch result {
            case .success(let notifications, _): GlobalStore.dispatch(SetNotifications(value: notifications))
            default: break
            }
        }
    }
}
