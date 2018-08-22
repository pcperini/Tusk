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
    
    var statusesNextPage: RequestRange? = nil
    var statusesPreviousPage: RequestRange? = nil
    lazy var statusesPaginatableData: PaginatingData<Status, Status> = PaginatingData<Status, Status>(provider: self.statusesProvider)
}
