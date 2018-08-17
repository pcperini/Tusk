//
//  TabViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/12/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift
import MastodonKit

class TabViewController: UITabBarController, StoreSubscriber {
    typealias StoreSubscriberStateType = AppState
    var state: AppState { return GlobalStore.state }
    var authFlowHandler: AuthFlowUIHandler!
    
    var notificationTab: UITabBarItem! { return self.tabBar.items!.first { (item) in item.tag == 10 } }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GlobalStore.subscribe(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.authFlowHandler = AuthFlowUIHandler(viewController: self, state: self.state.auth)
        self.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GlobalStore.unsubscribe(self)
    }
    
    func reloadData() {
        self.authFlowHandler.state = self.state.auth
        self.notificationTab.badgeValue = self.state.notifications.unreadCount > 0 ? " " : nil
    }
    
    func newState(state: AppState) {
        DispatchQueue.main.async {
            self.reloadData()
        }
    }
}
