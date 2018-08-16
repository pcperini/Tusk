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
    
    var notificationTab: UITabBarItem! { return self.tabBar.items![2] }
    
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
        self.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GlobalStore.unsubscribe(self)
    }
    
    func reloadData() {
        guard self.state.auth.instance != nil else {
            let alert = UIAlertController(title: "Login", message: "Select an instance", preferredStyle: .alert)
            alert.addTextField { (textField) in textField.text = AuthState.defaultInstance }
            alert.addAction(UIAlertAction(title: "Login", style: .default) { (action) in
                guard let instance = alert.textFields?.first?.text else { return }
                GlobalStore.dispatch(AuthState.SetInstance(value: instance))
            })
            
            self.present(alert,
                         animated: true,
                         completion: nil)
            
            return
        }
        
        if (GlobalStore.state.auth.code == nil && GlobalStore.state.auth.accessToken == nil) {
            // TODO: Move this
            let authURLComponents = Login.oauthURL(baseURL: GlobalStore.state.auth.baseURL!,
                                             clientID: "8d378392a7320d1c24b69bf7b908d91fadc91634996b5afaed9aad6a03c284ef",
                                             scopes: [.follow, .read, .write],
                                             redirectURI: "tusk://oauth")

            UIApplication.shared.open(try! authURLComponents!.asURL(), options: [:], completionHandler: nil)
            return
        }
        
        self.notificationTab.badgeValue = self.state.notifications.unreadCount > 0 ? "\(self.state.notifications.unreadCount)" : nil
    }
    
    func newState(state: AppState) {
        DispatchQueue.main.async {
            self.reloadData()
        }
    }
}
