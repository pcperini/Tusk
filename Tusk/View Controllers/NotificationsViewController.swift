//
//  NotificationsViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/10/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift
import MastodonKit
import SafariServices

class NotificationsViewController: PaginatingTableViewController<MKNotif>, SubscriptionResponder {
    lazy var subscriber: Subscriber = Subscriber(state: { $0.notifications }, newState: self.newState)
    
    var notifications: [MKNotif] = []
    lazy private var tableMergeHandler: TableViewMergeHandler<MKNotif> = TableViewMergeHandler(tableView: self.tableView,
                                                                                                      section: 0,
                                                                                                      dataComparator: ==)
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.subscriber.start()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pollNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.subscriber.stop()
    }
    
    func pollNotifications(pageDirection: PageDirection = .Reload(from: nil)) {
        guard let client = GlobalStore.state.auth.client else { return }
        let action: Action
        switch pageDirection {
        case .NextPage: action = NotificationsState.PollOlderNotifications(client: client)
        case .PreviousPage: action = NotificationsState.PollNewerNotifications(client: client)
        case .Reload: action = NotificationsState.PollNotifications(client: client)
        }
        
        GlobalStore.dispatch(action)
    }
    
    func newState(state: NotificationsState) {
        if (!state.notifications.isEmpty && state.notifications[0].createdAt != state.lastRead) {
            GlobalStore.dispatch(NotificationsState.SetLastReadDate(value: state.notifications[0].createdAt))
        }
        
        self.notifications = state.notifications
        self.tableMergeHandler.mergeData(data: self.notifications)
        
        self.updateUnreadIndicator()
        
        self.endRefreshing()
        self.endPaginating()
    }
    
    // MARK: Table View
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.notifications.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: NotificationViewCell = self.tableView.dequeueReusableCell(withIdentifier: "Notification",
                                                                            for: indexPath,
                                                                            usingNibNamed: "NotificationViewCell")
        
        let notification = self.notifications[indexPath.row]
        cell.notification = notification
        cell.avatarWasTapped = { self.pushToAccount(account: notification.account) }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notification = self.notifications[indexPath.row]
        switch notification.type {
        case .follow: self.pushToAccount(account: notification.account)
        default: self.pushToContext(status: notification.status)
        }
    }
    
    override func dataForRowAtIndexPath(indexPath: IndexPath) -> MKNotif? {
        if (self.notifications.isEmpty) { return nil }
        return self.notifications[indexPath.row]
    }
    
    // MARK: Paging
    override func refreshControlBeganRefreshing() {
        super.refreshControlBeganRefreshing()
        self.pollNotifications(pageDirection: .PreviousPage)
    }
    
    override func pageControlBeganRefreshing() {
        super.pageControlBeganRefreshing()
        self.pollNotifications(pageDirection: .NextPage)
    }
    
    // MARK: Navigation
    func pushToContext(status: Status?) {
        guard let status = status else { return }
        self.performSegue(withIdentifier: "PushContextViewController", sender: status)
        
        guard let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(ContextState.PollContext(client: client, status: status))
    }
    
    func pushToAccount(account: Account) {
        self.performSegue(withIdentifier: "PushAccountViewController", sender: account)
        
        guard let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(AccountState.PollAccount(client: client, account: account))
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
        case "PushContextViewController": do {
            guard let contextVC = segue.destination as? ContextViewController, let status = sender as? Status else {
                segue.destination.dismiss(animated: true, completion: nil)
                return
            }
            
            contextVC.status = status
            }
        default: return
        }
    }
}

