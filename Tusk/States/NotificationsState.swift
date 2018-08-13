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
    struct SetNotifications: Action {
        let value: [MastodonNotification]
        let merge: ([MastodonNotification], [MastodonNotification]) -> [MastodonNotification]
    }
    struct SetLastReadDate: Action { let value: Date }
    private struct SetPage: Action { let value: Pagination? }
    struct PollNotifications: Action { let client: Client }
    struct PollOlderNotifications: Action { let client: Client }
    struct PollNewerNotifications: Action { let client: Client }
    
    var notifications: [MastodonNotification] = []
    private var nextPage: RequestRange? // EARLIER statuses, the "next page" in reverse chronological order
    private var previousPage: RequestRange? // LATER statuses, the "prev page" in reverse chronological order
    
    var lastRead: Date = Date.distantPast
    var unreadCount: Int {
        return notifications.filter { (notif) in
            notif.createdAt > self.lastRead
        }.count
    }
    
    static func reducer(action: Action, state: NotificationsState?) -> NotificationsState {
        var state = state ?? NotificationsState()
        
        switch action {
        case let action as SetNotifications: state.notifications = action.merge(state.notifications, action.value)
        case let action as SetLastReadDate: state.lastRead = action.value
        case let action as SetPage: (state.nextPage, state.previousPage) = updatePages(pagination: action.value, state: state)
        case let action as PollNotifications: pollNotifications(client: action.client)
        case let action as PollOlderNotifications: pollNotifications(client: action.client, range: state.nextPage)
        case let action as PollNewerNotifications: pollNotifications(client: action.client, range: state.nextPage)
        default: break
        }
        
        return state
    }
    
    static func pollNotifications(client: Client, range: RequestRange? = nil) {
        let request: Request<[MastodonNotification]>
        let merge: ([MastodonNotification], [MastodonNotification]) -> [MastodonNotification]
        
        if let range = range {
            request = Notifications.all(range: range)
            switch range {
            case .since(_, _): merge = { (old, new) in new + old }
            case .max(_, _): merge = { (old, new) in old + new }
            default: merge = { (old, new) in new }
            }
        }
        else {
            request = Notifications.all()
            merge = { (old, new) in new }
        }
        
        client.run(request) { (result) in
            switch result {
            case .success(let notifications, let pagination): do {
                GlobalStore.dispatch(SetNotifications(value: notifications, merge: merge))
                GlobalStore.dispatch(SetPage(value: pagination))
            }
            default: break
            }
        }
    }
    
    static func updatePages(pagination: Pagination?, state: NotificationsState) -> (RequestRange?, RequestRange?) {
        guard let oldNext = state.nextPage, let oldPrev = state.previousPage else { return (pagination?.next, pagination?.previous) }
        guard let newNext = pagination?.next, let newPrev = pagination?.previous else { return (state.nextPage, state.previousPage) }
        
        let setNext: RequestRange? = newNext < oldNext ? newNext : oldNext
        let setPrev: RequestRange? = newPrev > oldPrev ? newPrev : oldPrev
        
        return (setNext, setPrev)
    }
}
