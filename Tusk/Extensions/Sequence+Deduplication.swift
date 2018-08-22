//
//  Sequence+Deduplication.swift
//  Tusk
//
//  Created by Patrick Perini on 8/22/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation

extension Sequence {
    func dedupe<T: Hashable>(on field: (Self.Element) throws -> T) rethrows -> [Self.Element] {
        return Array(try self.reduce([:], { (all, element) in
            all.merging([try field(element): element]) { (a, b) in a }
        }).values)
    }
}
