//
//  StatusesViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/10/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift
import MastodonKit
import SafariServices
import NYTPhotoViewer

class StatusesViewController: PaginatingTableViewController {
    private var statuses: [Status] = []
    var nextPageAction: () -> Action? = { nil }
    var previousPageAction: () -> Action? = { nil }
    var reloadAction: () -> Action? = { nil } { didSet { self.pollStatuses() } }
    
    private var selectedStatusIndex: Int? = nil {
        didSet {
            if let selectedIndex = self.selectedStatusIndex {
                self.tableView.insertRows(at: [IndexPath(row: selectedIndex + 1, section: 0)], with: .automatic)
            } else {
                guard let oldValue = oldValue else { return }
                self.tableView.deselectRow(at: IndexPath(row: oldValue, section: 0), animated: true)
                self.tableView.deleteRows(at: [IndexPath(row: oldValue + 1, section: 0)], with: .automatic)
            }
        }
    }
    
    func pollStatuses(pageDirection: PageDirection = .Reload) {
        let possibleAction: Action?
        switch pageDirection {
        case .NextPage: possibleAction = self.nextPageAction()
        case .PreviousPage: possibleAction = self.previousPageAction()
        case .Reload: possibleAction = self.reloadAction()
        }
        
        guard let action = possibleAction else { return }
        GlobalStore.dispatch(action)
    }
    
    func updateStatuses(statuses: [Status]) {
        self.endRefreshing()
        self.endPaginating()
        
        if (self.statuses != statuses) {
            self.statuses = statuses
            self.tableView.reloadData()
        }
    }
    
    // UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.statuses.count + (self.selectedStatusIndex == nil ? 0 : 1)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let statusIndex = self.statusIndexForIndexPath(indexPath: indexPath)
        if (statusIndex == NSNotFound) { // Action Cell
            guard let cell = self.tableView.dequeueReusableCell(withIdentifier: "Action") as? StatusActionViewCell else {
                self.tableView.register(UINib(nibName: "StatusActionViewCell", bundle: nil), forCellReuseIdentifier: "Action")
                return self.tableView(tableView, cellForRowAt: indexPath)
            }
            
            return cell
        }
        
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: "Status") as? StatusViewCell else {
            self.tableView.register(UINib(nibName: "StatusViewCell", bundle: nil), forCellReuseIdentifier: "Status")
            return self.tableView(tableView, cellForRowAt: indexPath)
        }
        
        let status = self.statuses[statusIndex]
        let displayStatus = status.reblog ?? status
        
        cell.originalStatus = status
        cell.attachmentWasTapped = { (attachment) in self.presentAttachment(attachment: attachment, forStatus: displayStatus) }
        cell.accountElementWasTapped = { (account) in
            guard let account = account else { return }
            self.pushToAccount(account: account)
        }
        cell.linkWasTapped = { (url) in
            guard let url = url else { return }
            self.pushToURL(url: url)
        }
        
        cell.status = displayStatus
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let selectedStatusIndex = self.selectedStatusIndex else { return indexPath }
        return indexPath.row != selectedStatusIndex + 1 ? indexPath : nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var statusIndex: Int? = self.statusIndexForIndexPath(indexPath: indexPath)
        if (statusIndex == self.selectedStatusIndex) { statusIndex = nil }
        
        self.tableView.beginUpdates()
        self.selectedStatusIndex = nil
        self.selectedStatusIndex = statusIndex
        self.tableView.endUpdates()
    }
    
    private func statusIndexForIndexPath(indexPath: IndexPath) -> Int {
        guard let selectedIndex = self.selectedStatusIndex, selectedIndex < indexPath.row else { return indexPath.row }
        if (indexPath.row == selectedIndex + 1) { return NSNotFound }
        return indexPath.row - 1
    }
    
    // Paging
    override func refreshControlBeganRefreshing() {
        super.refreshControlBeganRefreshing()
        self.pollStatuses(pageDirection: .PreviousPage)
    }
    
    override func pageControlBeganRefreshing() {
        super.pageControlBeganRefreshing()
        self.pollStatuses(pageDirection: .NextPage)
    }
    
    // Navigation
    func pushToURL(url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.navigationItem.title = "Mastodon"
        safariViewController.hidesBottomBarWhenPushed = true
        
        self.navigationController?.pushViewController(safariViewController, animated: true)
    }
    
    func pushToAccount(account: Account) {
        self.performSegue(withIdentifier: "PushAccountViewController", sender: account)
    }
    
    func presentAttachment(attachment: Attachment, forStatus status: Status) {
        let photoViewer = AttachmentsViewController(attachments: status.mediaAttachments, initialAttachment: attachment)
        self.present(photoViewer, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier {
        case "PushAccountViewController": do {
            guard let accountVC = segue.destination as? AccountViewController, let account = sender as? Account else {
                segue.destination.dismiss(animated: true, completion: nil)
                return
            }
            
            accountVC.account = account
            }
        default: return
        }
    }
}

