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
    
    var displayFields: [Account.Field] {
        let prepareForDisplay = { (value: String?) -> String? in
            guard let value = value else { return nil }
            return value.replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
                .replacingOccurrences(of: "&amp;", with: "&")
        }
        
        return self.fields.compactMap { (field) in
            let name = field.name
            guard let value = prepareForDisplay(field.value) else { return nil }
            let values = ["name": name, "value": value]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: values, options: .init(rawValue: 0)) else { return nil }
            return try? JSONDecoder().decode(Account.Field.self, from: jsonData)
        }
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

extension Status: Clonable {
    var allMediaAttachmentURLs: [String] {
        return self.mediaAttachments.reduce([]) { $0 + $1.allURLs }
    }
    
    var warning: String? {
        if self.spoilerText.isEmpty { return nil }
        return self.spoilerText
    }
    
    var sharableString: String {
        return (
            [NSAttributedString(htmlString: self.content)?.string ?? nil] +
            self.mediaAttachments.map { $0.textURL ?? $0.url }
        ).compactMap({ $0 }).joined(separator: " ")
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
    private static let RegexPrefix = "TuskRegex::"
    
    var isRegex: Bool {
        return self.phrase.starts(with: Filter.RegexPrefix)
    }
    
    var filterFunction: (Status) -> Bool {
        return { (status) in
            if self.isRegex {
                let regex = Regex(self.phrase.replacingOccurrences(of: Filter.RegexPrefix, with: ""))
                return !regex.test(input: status.content)
            }
            
            return !status.content.contains(self.phrase)
        }
    }
}
