//
//  List.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 1/2/18.
//  Copyright © 2018 MastodonKit. All rights reserved.
//

import Foundation

public class List: Codable {
    /// The ID of the list.
    public let id: String
    /// The Title of the list.
    public let title: String
    
    @available(*, deprecated, message: "Do not use.")
    init() {
        fatalError("Swift 4.1")
    }
}
