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
    override func state(appState: AppState) -> MentionsState {
        return appState.mentions
    }
    
    override func pollStatusesAction(client: Client, pageDirection: PageDirection) -> PollAction {
        switch pageDirection {
        case .NextPage: return MentionsState.PollOlderStatuses(client: client)
        case .PreviousPage: return MentionsState.PollNewerStatuses(client: client)
        case .Reload: return MentionsState.PollStatuses(client: client, startingAt: nil)
        }
    }
}
