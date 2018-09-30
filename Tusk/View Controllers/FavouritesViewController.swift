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
    override func state(appState: AppState) -> FavouritesState {
        return appState.favourites
    }
    
    override func pollStatusesAction(client: Client, pageDirection: PageDirection) -> PollAction {
        switch pageDirection {
        case .NextPage: return FavouritesState.PollOlderStatuses(client: client)
        case .PreviousPage: return FavouritesState.PollNewerStatuses(client: client)
        case .Reload: return FavouritesState.PollStatuses(client: client, startingAt: nil)
        }
    }
}
