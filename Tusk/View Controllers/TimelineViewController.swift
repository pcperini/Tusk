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

class TimelineViewController: UIViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = TimelineState
    var statusesViewController: StatusesViewController? {
        return self.childViewControllers.filter({ (child) in
            child is StatusesViewController
        }).first as? StatusesViewController
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GlobalStore.subscribe(self) { (subscription) in subscription.select { (state) in state.timeline } }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.statusesViewController?.nextPageAction = {
            guard let client = GlobalStore.state.auth.client else { return nil }
            return TimelineState.PollOlderStatuses(client: client)
        }
        
        self.statusesViewController?.previousPageAction = {
            guard let client = GlobalStore.state.auth.client else { return nil }
            return TimelineState.PollNewerStatuses(client: client)
        }
        
        self.statusesViewController?.reloadAction = {
            guard let client = GlobalStore.state.auth.client else { return nil }
            return TimelineState.PollStatuses(client: client)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GlobalStore.unsubscribe(self)
    }
    
    func newState(state: TimelineState) {
        DispatchQueue.main.async {
            self.statusesViewController?.updateStatuses(statuses: state.statuses)
        }
    }
}
