//
//  MastodonKit+Accessors.swift
//  Tusk
//
//  Created by Patrick Perini on 8/14/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import MastodonKit

extension Status {
    var plainContent: String {
        return self.content.plainHTMLString()
    }
}

extension Notification {
    var action: String {
        switch self.type {
        case .favourite: return "liked"
        case .mention: return self.status?.inReplyToID == nil ? "mentioned" : "replied"
        case .reblog: return "reposted"
        case .follow: return "followed you"
        }
    }
}

extension Account {
    var name: String {
        return self.displayName.isEmpty ? self.username : self.displayName
    }
    
    var handle: String {
        return "@\(self.username)"
    }
    
    var plainNote: String {
        return self.note.plainHTMLString()
    }
    
    var plainFields: [[String: String]] {
        return self.fields.map{ (pair) in
            return [
                "name": pair["name"]!.plainHTMLString(),
                "value": pair["value"]!.plainHTMLString()
            ]
        }
    }
}
