//
//  NotificationsViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/10/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift

class NotificationsViewController: UIViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = NotificationsState
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GlobalStore.subscribe(self) { (subscription) in subscription.select { (state) in state.notifications } }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pollNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GlobalStore.unsubscribe(self)
    }
    
    func pollNotifications() {
        guard let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(NotificationsState.PollNotifications(client: client))
    }
    
    func newState(state: NotificationsState) {
        print(state)
    }
}

