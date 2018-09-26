//
//  SearchViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 9/26/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit
import ReSwift

class SearchViewController: UITableViewController, SubscriptionResponder {
    enum Sections: String, CaseIterable {
        case Accounts = "Accounts"
        case Statuses = "Posts"
        case Hashtags = "Hashtags"
    }
    
    lazy var subscriber: Subscriber = Subscriber(state: { $0.search }, newState: self.newState)
    
    @IBOutlet var searchBar: UISearchBar!
    private var searchTerm: String? = nil
    private var results: (accounts: [Account], statuses: [Status], hashtags: [String]) = ([], [], []) {
        didSet {
            guard self.results != oldValue else { return }
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.subscriber.start()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.searchBar.becomeFirstResponder()
        self.tableView.visibleCells.forEach { (cell) in
            (cell as? StatusViewCell)?.hideSwipe(animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.subscriber.stop()
    }
    
    func newState(state: SearchState) {
        let newResults = state.results(forTerm: self.searchTerm ?? "")
        self.results = newResults
    }
    
    // MARK: Table View
    override func numberOfSections(in tableView: UITableView) -> Int {
        return (
            (self.results.accounts.isEmpty ? 0 : 1) +
            (self.results.statuses.isEmpty ? 0 : 1)
        )
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Sections.allCases[section].rawValue
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Sections.allCases[indexPath.section] {
        case .Accounts: return self.tableView(tableView, accountCellForRowAt: indexPath)
        case .Statuses: return self.tableView(tableView, statusCellForRowAt: indexPath)
        case .Hashtags: return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Sections.allCases[section] {
        case .Accounts: return self.results.accounts.count
        case .Statuses: return self.results.statuses.count
        case .Hashtags: return self.results.hashtags.count
        }
    }
    
    private func tableView(_ tableView: UITableView, accountCellForRowAt indexPath: IndexPath) -> FollowViewCell {
        let cell: FollowViewCell = tableView.dequeueReusableCell(withIdentifier: "Follow",
                                                                 for: indexPath,
                                                                 usingNibNamed: "FollowViewCell")
        
        cell.account = self.results.accounts[indexPath.row]
        return cell
    }
    
    private func tableView(_ tableView: UITableView, statusCellForRowAt indexPath: IndexPath) -> StatusViewCell {
        let cell: StatusViewCell = tableView.dequeueReusableCell(withIdentifier: "Status",
                                                                 for: indexPath,
                                                                 usingNibNamed: "StatusViewCell")
        
        let status = self.results.statuses[indexPath.row]
        let displayStatus = status.reblog ?? status
        
        cell.status = displayStatus
        cell.originalStatus = nil
        if (status != displayStatus) {
            cell.originalStatus = status
        }
        
        cell.isSupressingContent = (
            displayStatus.warning != nil &&
                !GlobalStore.state.storedDefaults.unsuppressedStatusIDs.contains(status.id) &&
                GlobalStore.state.storedDefaults.hideContentWarnings
        )
        
        cell.accountElementWasTapped = { self.pushAccount(account: $0) }
        cell.contextPushWasTriggered = { self.pushContext(status: $0) }
        cell.linkWasTapped = ModalHandler.handleLinkForViewController(viewController: self)
        cell.attachmentWasTapped = ModalHandler.handleAttachmentForViewController(viewController: self, status: displayStatus)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch Sections.allCases[indexPath.section] {
        case .Accounts: return FollowViewCell.rowHeight
        case .Statuses: return UITableViewAutomaticDimension
        case .Hashtags: return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Sections.allCases[indexPath.section] {
        case .Accounts: self.pushAccount(account: self.results.accounts[indexPath.row])
        case .Statuses: self.pushContext(status: self.results.statuses[indexPath.row])
        case .Hashtags: return
        }
    }
    
    // MARK: Navigation
    func pushAccount(account: AccountType) {
        guard let client = GlobalStore.state.auth.client else { return }
        self.performSegue(withIdentifier: "PushAccountViewController", sender: account)
        GlobalStore.dispatch(AccountState.PollAccount(client: client,
                                                      account: account))
    }
    
    func pushContext(status: Status) {
        guard let client = GlobalStore.state.auth.client else { return }
        self.performSegue(withIdentifier: "PushContextViewController", sender: status)
        GlobalStore.dispatch(ContextState.PollContext(client: client,
                                                      status: status))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch segue.identifier {
        case "PushAccountViewController": do {
            let sentAccount: AccountType? = (sender as? Account) ?? (sender as? AccountPlaceholder)
            guard let accountVC = segue.destination as? AccountViewController,
                let account = sentAccount else {
                    segue.destination.dismiss(animated: true, completion: nil)
                    return
            }
            accountVC.account = account
            }
        case "PushContextViewController": do {
            guard let contextVC = segue.destination as? ContextViewController,
                let status = sender as? Status else {
                    segue.destination.dismiss(animated: true, completion: nil)
                    return
            }
            contextVC.status = status
            }
        default: break
        }
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchTerm = searchText
        
        guard let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(SearchState.PollSearch(client: client, value: searchText))
    }
}
