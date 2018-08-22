//
//  MentionsViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/20/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift
import MastodonKit

class MentionsViewController: StatusesContainerViewController<MentionsState> {
    override func setUpSubscriptions() {
        GlobalStore.subscribe(self) { (subscription) in subscription.select { (state) in state.mentions } }
    }
    
    override func pollStatusesAction(client: Client, pageDirection: PageDirection) -> PollAction {
        switch pageDirection {
        case .NextPage: return StoreSubscriberStateType.PollOlderStatuses(client: client)
        case .PreviousPage: return StoreSubscriberStateType.PollNewerStatuses(client: client)
        case .Reload: return StoreSubscriberStateType.PollStatuses(client: client)
        }
    }
}
