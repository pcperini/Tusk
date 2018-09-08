//
//  MentionsState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/20/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import MastodonKit
import ReSwift

struct MentionsState: StatusesState {
    var statuses: [Status] = []
    var unsuppressedStatusIDs: [String] = []
    var filters: [(Status) -> Bool] = [
        { $0.visibility != .direct },
        { (status: Status) in
            status.mentions.first(where: { $0.id == GlobalStore.state.accounts.activeAccount?.account?.id }) != nil
        }
    ]
    
    var nextPage: RequestRange? = nil
    var previousPage: RequestRange? = nil
    var paginatingData: PaginatingData<Status, MKNotification> = PaginatingData<Status, MKNotification>(minimumPageSize: 10,
                                                                                                        typeMapper: MentionsState.typeMapper,
                                                                                                        provider: MentionsState.provider)
    
    static var additionalReducer: ((Action, MentionsState?) -> MentionsState)? = nil
    
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

