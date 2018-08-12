//
//  MessagesViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/10/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift

class MessagesViewController: UIViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = MessagesState
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GlobalStore.subscribe(self) { (subscription) in subscription.select { (state) in state.messages } }
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
        GlobalStore.dispatch(MessagesState.PollStatuses(client: client))
    }
    
    func newState(state: MessagesState) {
        print(state)
    }
}

