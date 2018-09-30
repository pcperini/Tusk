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

protocol StatusViewableState: StateType {
    var statuses: [Status] { get set }
}

class StatusesContainerViewController<StoreSubscriberStateType: StatusViewableState>: TableContainerViewController, SubscriptionResponder {
    private var hasLoadedInitialState: Bool = false
    var statusesViewController: StatusesViewController? {
        return self.tableViewController as? StatusesViewController
    }
    
    lazy var subscriber: Subscriber = Subscriber(state: { self.state(appState: $0) }, newState: { (state) in
        self.statusesViewController?.unsuppressedStatusIDs = GlobalStore.state.storedDefaults.unsuppressedStatusIDs
        self.statusesViewController?.updateStatuses(statuses: state.statuses)
        if (self.isViewLoaded && !self.hasLoadedInitialState) {
            self.loadInitialState()
        }
    })
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.subscriber.start()
    }
    
    func state(appState: AppState) -> StoreSubscriberStateType {
        fatalError("state has no valid abstract implementation")
    }
    
    func pollStatusesAction(client: Client, pageDirection: PageDirection) -> PollAction {
        fatalError("pollStatusesAction has no valid abstract implementation")
    }
    
    private func loadInitialState() {
        self.hasLoadedInitialState = true
        self.statusesViewController?.nextPageAction = {
            guard let client = GlobalStore.state.auth.client else { return nil }
            return self.pollStatusesAction(client: client, pageDirection: .NextPage)
        }
        
        self.statusesViewController?.previousPageAction = {
            guard let client = GlobalStore.state.auth.client else { return nil }
            return self.pollStatusesAction(client: client, pageDirection: .PreviousPage)
        }
        
        self.statusesViewController?.initialLastSeenID = GlobalStore.state.storedDefaults.lastSeenID(forContext: "\(StoreSubscriberStateType.self)")
        self.statusesViewController?.reloadAction = { (from) in
            guard let client = GlobalStore.state.auth.client else { return nil }
            return self.pollStatusesAction(client: client, pageDirection: .Reload(from: from))
        }
        
        self.statusesViewController?.didUpdateLastSeenData = {
            GlobalStore.dispatch(StoredDefaultsState.SetLastSeenID(context: "\(StoreSubscriberStateType.self)", value: $0.id))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.subscriber.stop()
    }
}
