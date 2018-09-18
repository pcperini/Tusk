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

class TabViewController: UITabBarController, SubscriptionResponder {
    var state: AppState { return GlobalStore.state }
    
    var notificationTab: UITabBarItem! { return self.tabBar.items!.first { (item) in item.tag == 10 } }
    private var tabSubsequentTapCounts: [UIViewController: Int] = [:]
    
    private var lastErrorDate: Date = Date()
    private var hasViewAppeared: Bool = false
    
    lazy var subscriber: Subscriber = Subscriber(state: { $0 }, newState: { (_) in self.reloadData() })
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.subscriber.start()
        
        self.hasViewAppeared = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
        self.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.subscriber.stop()
        
        self.hasViewAppeared = false
    }
    
    func reloadData() {
        if self.hasViewAppeared {
            AuthViewController.displayIfNeeded(fromViewController: self,
                                               usingSegueNamed: "PresentAuthViewController",
                                               sender: nil)
        }
        
        self.notificationTab.badgeValue = self.state.notifications.unreadCount > 0 ? " " : nil
        
        guard let latestError = self.state.errors.errors.last, latestError.1 > self.lastErrorDate else { return }
        self.lastErrorDate = latestError.1
        
        let alert = UIAlertController(title: "Whoops", message: "\(latestError.0)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
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
                tableView.delegate?.scrollViewDidEndDecelerating?(tableView)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.tabSubsequentTapCounts[viewController] = 0
        }
        
        return true
    }
}
