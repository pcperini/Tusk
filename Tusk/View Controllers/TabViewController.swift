//
//  TabViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/12/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift

class TabViewController: UITabBarController, StoreSubscriber {
    typealias StoreSubscriberStateType = AppState
    var state: AppState { return GlobalStore.state }
    
    var notificationTab: UITabBarItem! { return self.tabBar.items![2] }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GlobalStore.subscribe(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(TimelineState.PollStatuses(client: client, timeline: .Home))
        GlobalStore.dispatch(MessagesState.PollStatuses(client: client))
        GlobalStore.dispatch(NotificationsState.PollNotifications(client: client))
        GlobalStore.dispatch(AccountState.PollAccount(client: client))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GlobalStore.unsubscribe(self)
    }
    
    func reloadData() {
        notificationTab.badgeValue = state.notifications.unreadCount > 0 ? "\(state.notifications.unreadCount)" : nil
    }
    
    func newState(state: AppState) {
        DispatchQueue.main.async {
            self.reloadData()
        }
    }
}
