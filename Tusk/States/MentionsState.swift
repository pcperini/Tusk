//
//  MentionsState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/20/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import MastodonKit

struct MentionsState: StatusesState {    
    var statuses: [Status] = []
    var filters: [(Status) -> Bool] = [
        { $0.visibility != .direct },
        { (status: Status) in
            status.mentions.first(where: { $0.id == GlobalStore.state.account.activeAccount?.id }) != nil
        }
    ]
    
    var nextPage: RequestRange? = nil
    var previousPage: RequestRange? = nil
    var paginatingData: PaginatingData<Status> = PaginatingData<Status>()
}
