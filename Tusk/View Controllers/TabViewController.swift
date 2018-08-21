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
    var tabSubsequentTapCounts: [UIViewController: Int] = [:]
    
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
        self.delegate = self
        
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

extension TabViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let tapCount = (self.tabSubsequentTapCounts[viewController] ?? 0) + 1
        self.tabSubsequentTapCounts[viewController] = tapCount
        
        if (tapCount > 1) {
            var vc: UIViewController? = (viewController as? UINavigationController)?.topViewController
            if (vc as? TableContainerViewController != nil) { vc = (vc as? TableContainerViewController)?.tableViewController }
            
            if let tableViewController = vc as? UITableViewController, let tableView = tableViewController.tableView {
                tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.tabSubsequentTapCounts[viewController] = 0
        }
        
        return true
    }
}
