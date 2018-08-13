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

class NotificationsViewController: PaginatingTableViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = NotificationsState

    var notifications: [MKNotification] = []
    
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
    
    func pollNotifications(pageDirection: PageDirection = .Reload) {
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
        if (state.notifications.count > 0 && state.notifications[0].createdAt != state.lastRead) {
            GlobalStore.dispatch(NotificationsState.SetLastReadDate(value: state.notifications[0].createdAt))
        }
        
        DispatchQueue.main.async {
            if (self.notifications != state.notifications) {
                self.notifications = state.notifications
                self.tableView.reloadData()
            }
            
            self.endRefreshing()
            self.endPaginating()
        }
    }
    
    // UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.notifications.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        let notif = self.notifications[indexPath.row]
        let attributedText: NSAttributedString
        
        switch notif.type {
        case .mention: attributedText = notif.status!.content.attributedHTMLString()
        case .favourite: attributedText = NSAttributedString(string: "\(notif.account.displayName) favorited your post")
        case .follow: attributedText = NSAttributedString(string: "\(notif.account.displayName) followed you")
        case .reblog: attributedText = NSAttributedString(string: "\(notif.account.displayName) reposted your post")
        }
        
        cell?.textLabel?.attributedText = attributedText
        return cell!
    }
    
    override func refreshControlBeganRefreshing() {
        super.refreshControlBeganRefreshing()
        self.pollNotifications(pageDirection: .PreviousPage)
    }
    
    override func pageControlBeganRefreshing() {
        super.pageControlBeganRefreshing()
        self.pollNotifications(pageDirection: .NextPage)
    }
}

