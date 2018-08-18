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
import SafariServices

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
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: "Status") as? StatusViewCell else {
            self.tableView.register(UINib(nibName: "StatusViewCell", bundle: nil), forCellReuseIdentifier: "Status")
            return self.tableView(tableView, cellForRowAt: indexPath)
        }
        
        let status = self.statuses[indexPath.row]
        let displayStatus = status.reblog ?? status
        
        cell.originalStatus = status
        cell.accountElementWasTapped = { (account) in
            guard let account = account else { return }
            self.pushToAccount(account: account)
        }
        cell.linkWasTapped = { (url) in
            guard let url = url else { return }
            self.pushToURL(url: url)
        }
        
        cell.status = displayStatus
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let status = self.statuses[indexPath.row]
        guard let url = status.url else { return }
        
        self.pushToURL(url: url)
    }
    
    // Paging
    override func refreshControlBeganRefreshing() {
        super.refreshControlBeganRefreshing()
        self.pollStatuses(pageDirection: .PreviousPage)
    }
    
    override func pageControlBeganRefreshing() {
        super.pageControlBeganRefreshing()
        self.pollStatuses(pageDirection: .NextPage)
    }
    
    // Navigation
    func pushToURL(url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.navigationItem.title = "Mastodon"
        safariViewController.hidesBottomBarWhenPushed = true
        
        self.navigationController?.pushViewController(safariViewController, animated: true)
    }
    
    func pushToAccount(account: Account) {
        self.performSegue(withIdentifier: "PushAccountViewController", sender: account)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier {
        case "PushAccountViewController": do {
            guard let accountVC = segue.destination as? AccountViewController, let account = sender as? Account else {
                segue.destination.dismiss(animated: true, completion: nil)
                return
            }
            
            accountVC.account = account
            }
        default: return
        }
    }
}

