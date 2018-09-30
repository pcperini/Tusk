//
//  HashtagViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 9/27/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import ReSwift
import MastodonKit

class HashtagViewController: StatusesContainerViewController<HashtagState> {
    var hashtag: String!
    
    override func state(appState: AppState) -> HashtagState {
        return appState.search.activeHashtag!
    }
    
    override func pollStatusesAction(client: Client, pageDirection: PageDirection) -> PollAction {
        switch pageDirection {
        case .NextPage: return HashtagState.PollOlderStatuses(client: client)
        case .PreviousPage: return HashtagState.PollNewerStatuses(client: client)
        case .Reload: return HashtagState.PollStatuses(client: client, startingAt: nil)
        }
    }
}
