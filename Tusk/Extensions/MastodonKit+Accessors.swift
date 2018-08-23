//
//  MastodonKit+Accessors.swift
//  Tusk
//
//  Created by Patrick Perini on 8/14/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import MastodonKit


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
        return "@\(self.acct)"
    }
    
    var displayFields: [[String: String]] {
        let prepareForDisplay = { (value: String?) in
            (value ?? "").replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
                .replacingOccurrences(of: "&amp;", with: "&")
        }
        
        return self.fields.map { (field) in [ "name": field["name"]!, "value": prepareForDisplay(field["value"]) ] }
    }
    
    var behaviorTidbit: String {
        return "joined \(self.createdAt.toString(format: .custom("d MMM yyyy")))"
    }
}
