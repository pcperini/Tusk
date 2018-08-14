//
//  MastodonKit+Equatable.swift
//  Tusk
//
//  Created by Patrick Perini on 8/12/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import MastodonKit

extension Status: Equatable {
    public static func == (lhs: Status, rhs: Status) -> Bool {
        return lhs.id == rhs.id
    }
}

extension MastodonKit.Notification: Equatable {
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

extension Account: Hashable {
    public var hashValue: Int {
        return self.id.hashValue
    }

    
    public static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.id == rhs.id
    }
}
