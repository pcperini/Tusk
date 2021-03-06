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

typealias MKNotif = MastodonKit.Notification // overloaded with UIKit.Notification

struct NotificationsState: PaginatableState {
    typealias DataType = MKNotif
    
    struct SetNotifications: Action { let value: [MKNotif] }
    struct SetLastReadDate: Action { let value: Date }
    private struct SetPage: Action { let value: Pagination? }
    struct PollNotifications: Action { let client: Client }
    struct PollOlderNotifications: Action { let client: Client }
    struct PollNewerNotifications: Action { let client: Client }
    
    var notifications: [MKNotif] = []
    
    internal var nextPage: RequestRange? = nil
    internal var previousPage: RequestRange? = nil
    internal lazy var paginatingData: PaginatingData<MKNotif, MKNotif> = PaginatingData<MKNotif, MKNotif>(minimumPageSize: 0,
                                                                                                          provider: self.provider)
    
    private static let lastReadDefaultsKey = "notifications.lastRead"
    
    var lastRead: Date = UserDefaults.standard.value(forKey: NotificationsState.lastReadDefaultsKey) as? Date ?? Date.distantPast
    var unreadCount: Int {
        return notifications.filter { (notif) in
            notif.createdAt > self.lastRead
        }.count
    }
    
    static func reducer(action: Action, state: NotificationsState?) -> NotificationsState {
        var state = state ?? NotificationsState()
        
        switch action {
        case let action as SetNotifications: state.notifications = action.value
        case let action as SetLastReadDate: state.setLastRead(date: action.value)
        case let action as SetPage: (state.nextPage, state.previousPage) = state.paginatingData.updatedPages(pagination: action.value,
                                                                                                             nextPage: state.nextPage,
                                                                                                             previousPage: state.previousPage)
        case let action as PollNotifications: state.pollNotifications(client: action.client)
        case let action as PollOlderNotifications: state.pollNotifications(client: action.client, range: state.nextPage)
        case let action as PollNewerNotifications: state.pollNotifications(client: action.client, range: state.previousPage)
        default: break
        }
        
        return state
    }
    
    mutating func pollNotifications(client: Client, range: RequestRange? = nil) {
        self.paginatingData.pollData(client: client, range: range, existingData: self.notifications) { (
            notifications: [MKNotif],
            pagination: Pagination?
        ) in
            GlobalStore.dispatch(SetNotifications(value: notifications))
            GlobalStore.dispatch(SetPage(value: pagination))
        }
    }
    
    private mutating func setLastRead(date: Date) {
        self.lastRead = date
        
        UserDefaults.standard.set(date, forKey: NotificationsState.lastReadDefaultsKey)
        UserDefaults.standard.synchronize()
    }
    
    func provider(range: RequestRange? = nil) -> Request<[MKNotif]> {
        let range = range ?? .limit(30)
        return Notifications.all(range: range)
    }
}
