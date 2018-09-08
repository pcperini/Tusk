//
//  MessagesState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/11/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import MastodonKit
import ReSwift

// TODO: Think about how "threading" works here

struct MessagesState: StatusesState {
    var statuses: [Status] = []
    var unsuppressedStatusIDs: [String] = []
    var filters: [(Status) -> Bool] = [
        { $0.visibility == .direct }
    ]
    
    var nextPage: RequestRange? = nil
    var previousPage: RequestRange? = nil
    var paginatingData: PaginatingData<Status, MKNotification> = PaginatingData<Status, MKNotification>(minimumPageSize: 10,
                                                                                                        typeMapper: MessagesState.typeMapper,
                                                                                                        provider: MessagesState.provider)
    
    static var additionalReducer: ((Action, MessagesState?) -> MessagesState)? = nil
    
    static func provider(range: RequestRange? = nil) -> Request<[MKNotification]> {
        let range = range ?? .limit(30)
        var req = Notifications.all(range: range)
        
        switch range {
        case .since(_, _): req.cachePolicy = .reloadIgnoringCacheData
        default: req.cachePolicy = .returnCacheDataElseLoad
        }
        
        return req
    }
    
    static func typeMapper(notifications: [MKNotification]) -> [Status] {
        return notifications.compactMap { $0.status }
    }
}
