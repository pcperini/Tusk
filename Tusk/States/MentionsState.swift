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
    var baseFilters: [(Status) -> Bool] = [
        { $0.visibility != .direct },
        { (status: Status) in
            status.mentions.first(where: { $0.id == GlobalStore.state.accounts.activeAccount?.account?.id }) != nil
        }
    ]
    
    var nextPage: RequestRange? = nil
    var previousPage: RequestRange? = nil
    lazy var paginatingData: PaginatingData<Status, MKNotif> = PaginatingData<Status, MKNotif>(minimumPageSize: 10,
                                                                                                             typeMapper: MentionsState.typeMapper,
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

