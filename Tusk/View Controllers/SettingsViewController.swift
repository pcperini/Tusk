//
//  SettingsViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 9/5/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    static let bugURL: URL = URL(string: "https://github.com/pcperini/Tusk---Issues/issues")!
    
    @IBOutlet var versionLabel: UILabel!
    @IBOutlet var bugIcon: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.versionLabel.text = "\(Bundle.main.version) b\(Bundle.main.build)"
        self.bugIcon.tintColor = .white
    }
    
    @IBAction func dismiss(sender: UIBarButtonItem?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Table View
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath), let id = cell.reuseIdentifier else { return }
        switch id {
        case "SubmitBugButton": self.openBugReports()
        case "LogOutButton": self.logout()
        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: Navigation
    func openBugReports() {
        UIApplication.shared.open(SettingsViewController.bugURL,
                                  options: [:],
                                  completionHandler: nil)
    }
    
    func logout() {
        let confirmAlert = UIAlertController(title: "Are you sure you want to log out?",
                                             message: nil,
                                             preferredStyle: .alert)
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        confirmAlert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (_) in
            GlobalStore.dispatch(AuthState.ClearAuth())
            self.dismiss(sender: nil)
        }))
        
        self.present(confirmAlert, animated: true, completion: nil)
    }
}

class SettingsContainerViewController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalPresentationCapturesStatusBarAppearance = true
    }
}
