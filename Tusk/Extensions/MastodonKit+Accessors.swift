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

extension AccountType {
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

extension Attachment {
    var allURLs: [String] {
        return [self.url, self.previewURL, self.remoteURL, self.textURL].compactMap { $0 }
    }
}

extension Status {
    struct CloneError: Error { let description: String }
    var jsonValue: [String: Any]? {
        guard let jsonValue = try? JSONEncoder().encode(self),
            let jsonAttempt = try? JSONSerialization.jsonObject(with: jsonValue,options: .mutableContainers) else { return nil }
        return jsonAttempt as? [String: Any]
    }
    
    var allMediaAttachmentURLs: [String] {
        return self.mediaAttachments.reduce([]) { $0 + $1.allURLs }
    }
    
    func cloned(changes: [String: Any] = [:]) throws -> Status {
        guard var mutableJSONValue = self.jsonValue else {
            throw CloneError(description: "Could not serialize \(self)")
        }
        
        changes.forEach { (change) in mutableJSONValue[change.key] = change.value }
        let jsonData = try JSONSerialization.data(withJSONObject: mutableJSONValue, options: .init(rawValue: 0))
        
        return try JSONDecoder().decode(Status.self, from: jsonData)
    }
    
    func mentionHandlesForReply(activeAccount: AccountType? = nil) -> [String] {
        var handles = (
            [self.account.handle] +
            self.mentions.map { "@\($0.acct)" }
        )
        
        if let activeAccount = activeAccount {
            handles = handles.filter({ $0 != activeAccount.handle })
        }
        
        return handles
    }
}

extension Filter {
    var filterFunction: (Status) -> Bool {
        return { (status) in
            switch self.phrase {
            case _ where self.phrase.starts(with: "TuskRegex::"): do {
                let regex = Regex(self.phrase.replacingOccurrences(of: "TuskRegex::", with: ""))
                return !regex.test(input: status.content)
                }
            default: return !status.content.contains(self.phrase)
            }
        }
    }
}
