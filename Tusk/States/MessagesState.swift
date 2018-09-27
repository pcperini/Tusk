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
    var baseFilters: [(Status) -> Bool] = [
        { $0.visibility == .direct }
    ]
    
    var nextPage: RequestRange? = nil
    var previousPage: RequestRange? = nil
    lazy var paginatingData: PaginatingData<Status, MKNotif> = PaginatingData<Status, MKNotif>(minimumPageSize: 10,
                                                                                                             typeMapper: MessagesState.typeMapper,
                                                                                                             provider: self.provider)
        
    func provider(range: RequestRange? = nil) -> Request<[MKNotif]> {
        let range = range ?? .limit(30)
        var req = Notifications.all(range: range)
        
        switch range {
        case .since(_, _): req.cachePolicy = .reloadIgnoringCacheData
        default: req.cachePolicy = .returnCacheDataElseLoad
        }
        
        return req
    }
    
    static func typeMapper(notifications: [MKNotif]) -> [Status] {
        return notifications.compactMap { $0.status }
    }
}
