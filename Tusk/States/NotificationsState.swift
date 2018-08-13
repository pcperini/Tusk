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

struct NotificationsState: PaginatableState {
    typealias DataType = MastodonNotification
    
    struct SetNotifications: Action {
        let value: [MastodonNotification]
        let merge: PaginatingData<MastodonNotification>.MergeFunction
    }
    struct SetLastReadDate: Action { let value: Date }
    private struct SetPage: Action { let value: Pagination? }
    struct PollNotifications: Action { let client: Client }
    struct PollOlderNotifications: Action { let client: Client }
    struct PollNewerNotifications: Action { let client: Client }
    
    var notifications: [MastodonNotification] = []
    
    internal var nextPage: RequestRange? = nil
    internal var previousPage: RequestRange? = nil
    internal var paginatingData: PaginatingData<MastodonNotification> = PaginatingData<MastodonNotification>()
    
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
        case let action as SetPage: (state.nextPage, state.previousPage) = state.paginatingData.updatePages(pagination: action.value, state: state)
        case let action as PollNotifications: state.pollNotifications(client: action.client)
        case let action as PollOlderNotifications: state.pollNotifications(client: action.client, range: state.nextPage)
        case let action as PollNewerNotifications: state.pollNotifications(client: action.client, range: state.nextPage)
        default: break
        }
        
        return state
    }
    
    func pollNotifications(client: Client, range: RequestRange? = nil) {
        self.paginatingData.pollData(client: client, range: range, provider: NotificationsState.provider) { (
            notifications: [MastodonNotification],
            pagination: Pagination?,
            merge: @escaping PaginatingData<MastodonNotification>.MergeFunction
        ) in
            GlobalStore.dispatch(SetNotifications(value: notifications, merge: merge))
            GlobalStore.dispatch(SetPage(value: pagination))
        }
    }
    
    static func provider(range: RequestRange? = nil) -> Request<[MastodonNotification]> {
        guard let range = range else { return Notifications.all() }
        return Notifications.all(range: range)
    }
}
