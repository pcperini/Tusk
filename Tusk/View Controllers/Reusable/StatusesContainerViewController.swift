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

class StatusesContainerViewController<StoreSubscriberStateType: StatusesState>: TableContainerViewController, StoreSubscriber {
    var statusesViewController: StatusesViewController? {
        return self.tableViewController as? StatusesViewController
    }
    
    func setUpSubscriptions() {}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setUpSubscriptions()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.statusesViewController?.nextPageAction = {
            guard let client = GlobalStore.state.auth.client else { return nil }
            return StoreSubscriberStateType.PollOlderStatuses(client: client)
        }
        
        self.statusesViewController?.previousPageAction = {
            guard let client = GlobalStore.state.auth.client else { return nil }
            return StoreSubscriberStateType.PollNewerStatuses(client: client)
        }
        
        self.statusesViewController?.reloadAction = {
            guard let client = GlobalStore.state.auth.client else { return nil }
            return StoreSubscriberStateType.PollStatuses(client: client)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GlobalStore.unsubscribe(self)
    }
    
    func newState(state: StoreSubscriberStateType) {
        DispatchQueue.main.async {
            self.statusesViewController?.updateStatuses(statuses: state.statuses)
        }
    }
}
