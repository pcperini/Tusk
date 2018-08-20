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

struct TimelineState: StatusesState {
    var statuses: [Status] = []
    var filters: [(Status) -> Bool] = [{ $0.visibility != .direct }]
    
    var nextPage: RequestRange? = nil
    var previousPage: RequestRange? = nil
    var paginatingData: PaginatingData<Status> = PaginatingData<Status>()
}
