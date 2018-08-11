//
//  TimelineViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/10/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift

class TimelineViewController: UIViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = TimelineState

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GlobalStore.subscribe(self) { (subscription) in subscription.select { (state) in state.timeline } }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pollStatuses()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GlobalStore.unsubscribe(self)
    }
    
    func pollStatuses() {
        guard let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(TimelineState.PollStatuses(client: client, timeline: .Home))
    }
    
    func newState(state: TimelineState) {
        print(state)
    }
}

