//
//  FavouritesViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/24/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift
import MastodonKit

class FavouritesViewController: StatusesContainerViewController<FavouritesState> {
    override func setUpSubscriptions() {
        GlobalStore.subscribe(self) { (subscription) in subscription.select { (state) in state.favourites } }
    }
    
    override func pollStatusesAction(client: Client, pageDirection: PageDirection) -> PollAction {
        switch pageDirection {
        case .NextPage: return StoreSubscriberStateType.PollOlderStatuses(client: client)
        case .PreviousPage: return StoreSubscriberStateType.PollNewerStatuses(client: client)
        case .Reload: return StoreSubscriberStateType.PollStatuses(client: client)
        }
    }
}
