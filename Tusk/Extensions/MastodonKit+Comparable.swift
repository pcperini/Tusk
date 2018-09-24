//
//  MastodonKit+Equatable.swift
//  Tusk
//
//  Created by Patrick Perini on 8/12/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import MastodonKit

extension Status: Paginatable {
    static let sortedByPageIndex: Bool = false
    public var hashValue: Int {
        return self.id.hashValue
    }
    
    public static func < (lhs: Status, rhs: Status) -> Bool {
        return lhs.createdAt < rhs.createdAt
    }
    
    public static func == (lhs: Status, rhs: Status) -> Bool {
        return lhs.id == rhs.id
    }
}

extension MastodonKit.Notification: Paginatable {
    static let sortedByPageIndex: Bool = false
    public var hashValue: Int {
        return self.id.hashValue
    }
    
    public static func < (lhs: Notification, rhs: Notification) -> Bool {
        return lhs.createdAt < rhs.createdAt
    }
    
    public static func == (lhs: MastodonKit.Notification, rhs: MastodonKit.Notification) -> Bool {
        return lhs.id == rhs.id
    }
}

extension RequestRange: Comparable {
    public static func < (lhs: RequestRange, rhs: RequestRange) -> Bool {
        switch (lhs, rhs) {
        case (.max(let lhID as NSString, _), .max(let rhID as NSString, _)): return lhID.longLongValue < rhID.longLongValue
        case (.since(let lhID as NSString, _), .since(let rhID as NSString, _)): return lhID.longLongValue < rhID.longLongValue
        default: return false
        }
    }
}

extension Account: Paginatable {
    static let sortedByPageIndex = true
    public var hashValue: Int {
        return self.id.hashValue
    }
    
    public static func < (lhs: Account, rhs: Account) -> Bool {
        return lhs.createdAt < rhs.createdAt
    }
    
    public static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Attachment: Hashable {
    public var hashValue: Int {
        return self.id.hashValue
    }
    
    public static func == (lhs: Attachment, rhs: Attachment) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Relationship: Equatable {
    public static func == (lhs: Relationship, rhs: Relationship) -> Bool {
        return (
            lhs.id == rhs.id &&
            lhs.blocking == rhs.blocking &&
            lhs.domainBlocking == rhs.domainBlocking &&
            lhs.followedBy == rhs.followedBy &&
            lhs.following == rhs.following &&
            lhs.muting == rhs.muting &&
            lhs.mutingNotifications == rhs.mutingNotifications &&
            lhs.requested == rhs.requested
        )
    }
}

extension Filter: Paginatable {
    static let sortedByPageIndex = true
    public var hashValue: Int {
        return self.content.hashValue
    }
    
    public static func < (lhs: Filter, rhs: Filter) -> Bool {
        return lhs.id < rhs.id
    }
    
    public static func == (lhs: Filter, rhs: Filter) -> Bool {
        return lhs.id == rhs.id
    }
}
