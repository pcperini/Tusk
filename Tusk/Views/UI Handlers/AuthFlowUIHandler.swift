//
//  AuthFlowHandler.swift
//  Tusk
//
//  Created by Patrick Perini on 8/16/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

struct AuthFlowUIHandler {
    let viewController: UIViewController
    var state: AuthState { didSet { self.reloadData() } }
    
    func reloadData() {
        if (self.state.instance == nil) {
            let alert = UIAlertController(title: "Login", message: "Select an instance", preferredStyle: .alert)
            alert.addTextField { (textField) in textField.text = AuthState.defaultInstance }
            alert.addAction(UIAlertAction(title: "Login", style: .default) { (action) in
                guard let instance = alert.textFields?.first?.text else { return }
                GlobalStore.dispatch(AuthState.SetInstance(value: instance))
            })
            
            self.viewController.present(alert, animated: true, completion: nil)
        } else if (self.state.code == nil && self.state.accessToken == nil) {
            UIApplication.shared.open(self.state.oauthURL!, options: [:], completionHandler: nil)
        }
    }
}
