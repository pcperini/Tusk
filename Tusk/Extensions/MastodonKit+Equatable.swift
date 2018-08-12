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
