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
    
    public static func save(id: Int?, phrase: String, contexts: [String]) -> Request<Filter> {
        let parameters = [
            Parameter(name: "phrase", value: phrase),
        ] + contexts.map({ Parameter(name: "context[]", value: $0) })
        
        let method: HTTPMethod
        let path: String
        
        if let id = id {
            method = HTTPMethod.put(.parameters(parameters))
            path = "/api/v1/filters/\(id)"
        } else {
            method = HTTPMethod.post(.parameters(parameters))
            path = "/api/v1/filters"
        }
        
        return Request<Filter>(path: path, method: method)
    }
    
    public static func delete(id: Int) -> Request<Empty> {
        return Request<Empty>(path: "/api/v1/filters/\(id)", method: .delete(.empty))
    }
}

