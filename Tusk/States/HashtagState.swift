//
//  HashtagState.swift
//  Tusk
//
//  Created by Patrick Perini on 9/27/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import MastodonKit
import ReSwift

protocol HashtagAction: Action { var hashtag: String { get } }

struct HashtagState: StatusesState {
    var hashtag: String = ""
    var statuses: [Status] = []
    var baseFilters: [(Status) -> Bool] = []
    
    var nextPage: RequestRange? = nil
    var previousPage: RequestRange? = nil
    lazy var paginatingData: PaginatingData<Status, Status> = PaginatingData<Status, Status>(provider: self.provider)
    
    func provider(range: RequestRange? = nil) -> Request<[Status]> {
        let range = range ?? .limit(40)
        return Timelines.tag(self.hashtag, local: false, range: range)
    }
}
