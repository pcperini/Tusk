//
//  PaginatingTableViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/12/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

class PaginatingTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(_refreshControlBeganRefreshing), for: .allEvents)
    }

    @objc private func _refreshControlBeganRefreshing() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            self.refreshControlBeganRefreshing()
        }
    }
    
    func refreshControlBeganRefreshing() {
        self.refreshControl?.endRefreshing()
    }
}
