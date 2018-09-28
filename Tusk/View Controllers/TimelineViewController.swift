//
//  TimelineViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/19/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift
import MastodonKit

class TimelineViewController: StatusesContainerViewController<TimelineState> {
    override func state(appState: AppState) -> TimelineState {
        return appState.timeline
    }
    
    override func pollStatusesAction(client: Client, pageDirection: PageDirection) -> PollAction {
        switch pageDirection {
        case .NextPage: return TimelineState.PollOlderStatuses(client: client)
        case .PreviousPage: return TimelineState.PollNewerStatuses(client: client)
        case .Reload: return TimelineState.PollStatuses(client: client)
        }
    }
}
