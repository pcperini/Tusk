//
//  NotificationsViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/10/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift

class NotificationsViewController: UITableViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = NotificationsState
    var state: NotificationsState { return GlobalStore.state.notifications }
    
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
        if state.notifications[0].createdAt != state.lastRead {
            GlobalStore.dispatch(NotificationsState.SetLastReadDate(value: state.notifications[0].createdAt))
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    // UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.state.notifications.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "Cell")
        
        let notif = self.state.notifications[indexPath.row]
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
}

