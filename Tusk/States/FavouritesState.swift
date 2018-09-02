//
//  FavouritesState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/24/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import MastodonKit
import ReSwift

struct FavouritesState: StatusesState {
    var statuses: [Status] = []
    var unsuppressedStatusIDs: [String] = []
    var readPositionStatusID: String? = nil
    
    var filters: [(Status) -> Bool] = []
    
    var nextPage: RequestRange? = nil
    var previousPage: RequestRange? = nil
    var paginatingData: PaginatingData<Status, Status> = PaginatingData<Status, Status>(provider: FavouritesState.provider)
    
    static var additionalReducer: ((Action, FavouritesState?) -> FavouritesState)? = nil
    
    static func provider(range: RequestRange? = nil) -> Request<[Status]> {
        guard let range = range else { return Favourites.all(range: .limit(40)) }
        return Favourites.all(range: range)
    }
}
