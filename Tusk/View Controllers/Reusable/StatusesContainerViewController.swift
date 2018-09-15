//
//  StatusesContainerViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/20/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit
import ReSwift

protocol StatusViewableState {
    var statuses: [Status] { get set }
    var unsuppressedStatusIDs: [String] { get set }
}

class StatusesContainerViewController<StoreSubscriberStateType: StatusViewableState>: TableContainerViewController, StoreSubscriber {
    var statusesViewController: StatusesViewController? {
        return self.tableViewController as? StatusesViewController
    }
    
    func setUpSubscriptions() {}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setUpSubscriptions()
    }
    
    func pollStatusesAction(client: Client, pageDirection: PageDirection) -> PollAction {
        fatalError("pollStatusesAction has no valid abstract implementation")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.statusesViewController?.nextPageAction = {
            guard let client = GlobalStore.state.auth.client else { return nil }
            return self.pollStatusesAction(client: client, pageDirection: .NextPage)
        }
        
        self.statusesViewController?.previousPageAction = {
            guard let client = GlobalStore.state.auth.client else { return nil }
            return self.pollStatusesAction(client: client, pageDirection: .PreviousPage)
        }
        
        self.statusesViewController?.reloadAction = {
            guard let client = GlobalStore.state.auth.client else { return nil }
            return self.pollStatusesAction(client: client, pageDirection: .Reload)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GlobalStore.unsubscribe(self)
    }
    
    func newState(state: StoreSubscriberStateType) {
        DispatchQueue.main.async {
            self.statusesViewController?.unsuppressedStatusIDs = state.unsuppressedStatusIDs
            self.statusesViewController?.updateStatuses(statuses: state.statuses)
        }
    }
}
