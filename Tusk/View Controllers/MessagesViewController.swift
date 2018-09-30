//
//  MessagesViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/20/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift
import MastodonKit

// TODO: Think about how "threading" works here

class MessagesViewController: StatusesContainerViewController<MessagesState> {
    override func state(appState: AppState) -> MessagesState {
        return appState.messages
    }
    
    override func pollStatusesAction(client: Client, pageDirection: PageDirection) -> PollAction {
        switch pageDirection {
        case .NextPage: return MessagesState.PollOlderStatuses(client: client)
        case .PreviousPage: return MessagesState.PollNewerStatuses(client: client)
        case .Reload: return MessagesState.PollStatuses(client: client, startingAt: nil)
        }
    }
}
