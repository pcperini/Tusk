//
//  MastodonKit+Placeholders.swift
//  Tusk
//
//  Created by Patrick Perini on 8/25/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import MastodonKit

extension Account: AccountType {}
protocol AccountType {
    var id: String { get }
    var username: String { get }
    var acct: String { get }
    var displayName: String { get }
    var note: String { get }
    var url: String { get }
    var avatar: String { get }
    var avatarStatic: String { get }
    var header: String { get }
    var headerStatic: String { get }
    var locked: Bool { get }
    var createdAt: Date { get }
    var followersCount: Int { get }
    var followingCount: Int { get }
    var statusesCount: Int { get }
    var fields: [Account.Field] { get }
    var bot: Bool? { get }
    
    static var sortedByPageIndex: Bool { get }
    var hashValue: Int { get }
}

struct AccountPlaceholder: AccountType {
    var hashValue: Int { return self.id.hashValue }
    static func < (lhs: AccountPlaceholder, rhs: AccountPlaceholder) -> Bool {
        return lhs.createdAt < rhs.createdAt
    }
    
    static var sortedByPageIndex: Bool { return false }
    
    let id: String
    var username: String { return "" }
    var acct: String { return "" }
    var displayName: String { return "" }
    var note: String { return "" }
    var url: String { return "" }
    var avatar: String { return "" }
    var avatarStatic: String { return "" }
    var header: String { return "" }
    var headerStatic: String { return "" }
    var locked: Bool { return false }
    var createdAt: Date {return  Date() }
    var followersCount: Int { return 0 }
    var followingCount: Int { return 0 }
    var statusesCount: Int { return 0 }
    var fields: [Account.Field] { return [] }
    var bot: Bool? { return nil }
}

extension Status: StatusType {}
protocol StatusType {
    var content: String { get }
    var visibility: Visibility { get }
    var inReplyToID: String? { get }
    var mentions: [Mention] { get }
}

struct StatusPlaceholder: StatusType {
    let content: String
    let visibility: Visibility
    let inReplyToID: String?
    let mentions: [Mention]
}
