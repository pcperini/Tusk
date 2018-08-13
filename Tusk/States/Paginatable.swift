//
//  Paginatable.swift
//  Tusk
//
//  Created by Patrick Perini on 8/13/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import MastodonKit
import ReSwift

protocol Paginatable<DatatType> {
    var nextPage: RequestRange? { get set } // EARLIER statuses, the "next page" in reverse chronological order
    var previousPage: RequestRange? { get set } // LATER statuses, the "prev page" in reverse chronological order
    
    func mergeForRange(range: RequestRange?) -> (([DataType], [DataType]) -> )
}
