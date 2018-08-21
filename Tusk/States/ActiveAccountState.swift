//
//  ActiveAccountState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/12/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import MastodonKit
import ReSwift

struct ActiveAccountState: AccountStateType {    
    var account: Account? = nil
    var pinnedStatuses: [Status] = []
    var following: [Account] = []
    var followers: [Account] = []
    var statuses: [Status] = []
}
