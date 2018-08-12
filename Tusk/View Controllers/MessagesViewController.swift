//
//  MessagesViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/10/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift

class MessagesViewController: UITableViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = MessagesState
    var state: MessagesState { return GlobalStore.state.messages }
    
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
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    // UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.state.statuses.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "Cell")
        cell?.textLabel?.attributedText = self.state.statuses[indexPath.row].content.attributedHTMLString()
        return cell!
    }
}

