//
//  TimelineViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/10/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift
import MastodonKit

class TimelineViewController: PaginatingTableViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = TimelineState

    var statuses: [Status] = []

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
    
    func pollStatuses(pageDirection: PageDirection = .Reload) {
        guard let client = GlobalStore.state.auth.client else { return }
        let action: Action
        switch pageDirection {
        case .NextPage: action = TimelineState.PollOlderStatuses(client: client)
        case .PreviousPage: action = TimelineState.PollNewerStatuses(client: client)
        case .Reload: action = TimelineState.PollStatuses(client: client)
        }
        
        GlobalStore.dispatch(action)
    }
    
    func newState(state: TimelineState) {
        DispatchQueue.main.async {
            self.endRefreshing()
            self.endPaginating()
            
            if (self.statuses != state.statuses) {
                self.statuses = state.statuses
                self.tableView.reloadData()
            }
        }
    }
    
    // UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.statuses.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "Cell")
        cell?.textLabel?.attributedText = self.statuses[indexPath.row].content.attributedHTMLString()
        return cell!
    }
    
    override func refreshControlBeganRefreshing() {
        super.refreshControlBeganRefreshing()
        self.pollStatuses(pageDirection: .PreviousPage)
    }
    
    override func pageControlBeganRefreshing() {
        super.pageControlBeganRefreshing()
        self.pollStatuses(pageDirection: .NextPage)
    }
}

