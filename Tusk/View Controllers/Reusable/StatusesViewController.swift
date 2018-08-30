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

class StatusesViewController: PaginatingTableViewController<Status> {
    private var statuses: [Status] = []
    lazy private var tableMergeHandler: TableViewMergeHandler<Status> = TableViewMergeHandler(tableView: self.tableView,
                                                                                              data: nil,
                                                                                              selectedElement: nil,
                                                                                              dataComparator: self.statusesAreEqual)
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.visibleCells.forEach { (cell) in
            (cell as? StatusViewCell)?.hideSwipe(animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.contentInsetAdjustmentBehavior = .never
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

        self.statuses = statuses
        self.tableMergeHandler.mergeData(data: statuses)
        
        self.updateUnreadIndicator()
    }
    
    // MARK: Table View
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.statuses.count + (self.selectedStatusIndex == nil ? 0 : 1)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let statusIndex = self.statusIndexForIndexPath(indexPath: indexPath)
        if (statusIndex == NSNotFound) { // Action Cell
            let statusIndex = indexPath.row - 1
            let status = self.statuses[statusIndex]
            let displayStatus = status.reblog ?? status
            
            let cell: StatusActionViewCell = self.tableView.dequeueReusableCell(withIdentifier: "Action",
                                                                                for: indexPath,
                                                                                usingNibNamed: "StatusActionViewCell")
            
            cell.replyButtonWasTapped = {
                self.selectedStatusIndex = nil
                self.performSegue(withIdentifier: "PresentComposeViewController", sender: displayStatus)
            }
            
            cell.favouriteButton.isSelected = displayStatus.favourited ?? false
            cell.favouritedButtonWasTapped = {
                guard let client = GlobalStore.state.auth.client else { return }
                cell.favouriteButton.isSelected = !cell.favouriteButton.isSelected
                GlobalStore.dispatch(TimelineState.ToggleFavourite(client: client, status: displayStatus))
            }
            
            cell.reblogButton.isSelected = displayStatus.reblogged ?? false
            cell.reblogButtonWasTapped = {
                guard let client = GlobalStore.state.auth.client else { return }
                cell.reblogButton.isSelected = !cell.reblogButton.isSelected
                GlobalStore.dispatch(TimelineState.ToggleReblog(client: client, status: displayStatus))
            }
            
            return cell
        }
        
        let cell: StatusViewCell = self.tableView.dequeueReusableCell(withIdentifier: "Status",
                                                                      for: indexPath,
                                                                      usingNibNamed: "StatusViewCell")
        let status = self.statuses[statusIndex]
        let displayStatus = status.reblog ?? status
        
        cell.originalStatus = nil
        if (status != displayStatus) {
            cell.originalStatus = status
        }
        
        cell.attachmentWasTapped = { (attachment) in
            self.presentAttachment(attachment: attachment, forStatus: displayStatus)
        }
        cell.accountElementWasTapped = { (account) in
            guard let account = account else { return }
            self.pushToAccount(account: account)
        }
        cell.linkWasTapped = { (url, text) in
            if let mentionMatch = status.mentions.first(where: { text.hasSuffix($0.acct) }) {
                self.pushToAccount(account: AccountPlaceholder(id: mentionMatch.id))
                return
            }
            
            guard let url = url else { return }
            self.openURL(url: url)
        }
        cell.contextPushWasTriggered = { (status) in
            guard let status = status else { return }
            self.pushToContext(status: status)
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
        
        self.tableMergeHandler.selectedElement = nil
        if let statusIndex = statusIndex {
            self.tableMergeHandler.selectedElement = self.statuses[statusIndex]
        }
        
        self.tableView.beginUpdates()
        self.selectedStatusIndex = nil
        self.selectedStatusIndex = statusIndex
        self.tableView.endUpdates()
    }
    
    override func dataForRowAtIndexPath(indexPath: IndexPath) -> Status? {
        let index = self.statusIndexForIndexPath(indexPath: indexPath)
        guard index != NSNotFound, !self.statuses.isEmpty else { return nil }
        return self.statuses[index]
    }
    
    private func statusIndexForIndexPath(indexPath: IndexPath) -> Int {
        guard let selectedIndex = self.selectedStatusIndex, selectedIndex < indexPath.row else { return indexPath.row }
        if (indexPath.row == selectedIndex + 1) { return NSNotFound }
        return indexPath.row - 1
    }
    
    private func statusesAreEqual(lhs: Status, rhs: Status) -> Bool {
        return (
            lhs.id == rhs.id &&
            lhs.favourited == rhs.favourited &&
            lhs.reblogged == rhs.reblogged &&
            lhs.reblog?.favourited == rhs.reblog?.favourited &&
            lhs.reblog?.reblogged == rhs.reblog?.reblogged
        )
    }
    
    // MARK: Paging
    override func refreshControlBeganRefreshing() {
        super.refreshControlBeganRefreshing()
        self.pollStatuses(pageDirection: .PreviousPage)
    }
    
    override func pageControlBeganRefreshing() {
        super.pageControlBeganRefreshing()
        self.pollStatuses(pageDirection: .NextPage)
    }
    
    // MARK: Navigation
    func openURL(url: URL) {
        UIApplication.shared.open(url,options: [:], completionHandler: nil)
    }
    
    func pushToAccount(account: AccountType) {
        self.performSegue(withIdentifier: "PushAccountViewController", sender: account)
        
        guard let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(AccountState.PollAccount(client: client, account: account))
    }
    
    func pushToContext(status: Status) {
        self.performSegue(withIdentifier: "PushContextViewController", sender: status)
        
        guard let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(ContextState.PollContext(client: client, status: status))
    }
    
    func presentAttachment(attachment: Attachment, forStatus status: Status) {
        let photoViewer = AttachmentsViewController(attachments: status.mediaAttachments, initialAttachment: attachment)
        self.present(photoViewer, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier {
        case "PushAccountViewController": do {
            let sentAccount: AccountType? = (sender as? Account) ?? (sender as? AccountPlaceholder)
            guard let accountVC = segue.destination as? AccountViewController, let account = sentAccount else {
                segue.destination.dismiss(animated: true, completion: nil)
                return
            }
            
            accountVC.account = account
            }
        case "PushContextViewController": do {
            guard let contextVC = segue.destination as? ContextViewController, let status = sender as? Status else {
                segue.destination.dismiss(animated: true, completion: nil)
                return
            }
            
            contextVC.status = status
            }
        case "PresentComposeViewController": do {
            guard let container = segue.destination as? ComposeContainerViewController,
                let composeVC = container.composeViewController,
                let status = sender as? Status else { return }
            composeVC.inReplyTo = status
            }
        default: return
        }
    }
}

