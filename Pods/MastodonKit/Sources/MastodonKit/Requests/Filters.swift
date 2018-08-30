//
//  Filters.swift
//  MastodonKit
//
//  Created by Patrick Perini on 8/30/18.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public struct Filters {
    /// Fetches a list of filters.
    ///
    /// - Returns: Request for `[Filter]`.
    public static func all() -> Request<[Filter]> {
        let method = HTTPMethod.get(.empty)
        return Request<[Filter]>(path: "/api/v1/filters", method: method)
    }
}

