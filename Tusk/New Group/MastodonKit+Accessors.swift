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
        return self.content.attributedHTMLString().string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
