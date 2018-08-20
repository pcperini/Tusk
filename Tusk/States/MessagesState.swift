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
    var filters: [(Status) -> Bool] = [
        { $0.visibility == .direct && $0.account != GlobalStore.state.account.activeAccount }
    ]
    
    var nextPage: RequestRange? = nil
    var previousPage: RequestRange? = nil
    var paginatingData: PaginatingData<Status> = PaginatingData<Status>(minimumPageSize: 10)
}
