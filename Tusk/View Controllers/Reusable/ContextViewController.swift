//
//  ContextViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/23/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift
import MastodonKit

class ContextViewController: StatusesContainerViewController<ContextState> {
    var status: Status!
    var contextState: ContextState! {
        return GlobalStore.state.contexts.contextForStatusWithID(id: self.status.id)
    }
    
    override func setUpSubscriptions() {
        GlobalStore.subscribe(self) { (subscription) in subscription.select { (state) in state.contexts.contextForStatusWithID(id: self.status.id)! } }
    }
    
    override func pollStatusesAction(client: Client, pageDirection: PageDirection) -> PollAction {
        return StoreSubscriberStateType.PollContext(client: client, status: self.status)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.statusesViewController?.refreshingEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            guard let row = self.contextState.context?.ancestors.count else { return }
            self.statusesViewController?.tableView.scrollToRow(at: IndexPath(row: row, section: 0),
                                                               at: .top,
                                                               animated: true)
        }
    }
}
