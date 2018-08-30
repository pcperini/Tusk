//
//  Filter.swift
//  MastodonKit
//
//  Created by Patrick Perini on 8/30/18.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public class Filter: Codable {
    /// String that contains keyword or phrase.
    public let phrase: String
    /// Array of strings that means filtering context. Each string is one of 'home', 'notifications', 'public', 'thread'. At least one context must be specified.
    public let contexts: [String]
    /// Boolean that indicates irreversible filtering on server side.
    public let irreversible: Bool?
    /// Boolean that indicates word match.
    public let wholeWord: Bool?
    /// Number that indicates seconds. Filter will be expire in seconds after API processed. Null or blank string means "don't change". Default is unlimited.
    public let expiresAt: String?
    
    private enum CodingKeys: String, CodingKey {
        case phrase
        case contexts = "context"
        case irreversible
        case wholeWord = "whole_word"
        case expiresAt = "expires_at"
    }
    
    @available(*, deprecated, message: "Do not use.")
    init() {
        fatalError("Swift 4.1")
    }
}
