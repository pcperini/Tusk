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
    typealias Results = (accounts: [Account], statuses: [Status], hashtags: [String])
    
    enum Section: String, CaseIterable {
        case Accounts = "Accounts"
        case Hashtags = "Hashtags"
        case Statuses = "Posts"
        
        static func casesForResults(results: Results) -> [Section] {
            return (
                (results.accounts.isEmpty ? [] : [.Accounts]) +
                (results.hashtags.isEmpty ? [] : [.Hashtags]) +
                (results.statuses.isEmpty ? [] : [.Statuses])
            )
        }
    }
    
    lazy var subscriber: Subscriber = Subscriber(state: { $0.search }, newState: self.newState)
    
    @IBOutlet var searchBar: UISearchBar!
    private var searchTerm: String? = nil
    
    private var sections: [Section] { return Section.casesForResults(results: self.results) }
    private var results: Results = ([], [], []) {
        didSet {
            guard self.results != oldValue else { return }
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchBar.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.subscriber.start()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        return self.sections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section].rawValue
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard self.sections[section] == .Statuses else { return nil }
        return "Posts are limited to those you've interacted with"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.sections[indexPath.section] {
        case .Accounts: return self.tableView(tableView, accountCellForRowAt: indexPath)
        case .Statuses: return self.tableView(tableView, statusCellForRowAt: indexPath)
        case .Hashtags: return self.tableView(tableView, hashtagCellForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.sections[section] {
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
    
    private func tableView(_ tableView: UITableView, hashtagCellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HashtagCell") ?? UITableViewCell(style: .default,
                                                                                                   reuseIdentifier: "HashtagCell")
        cell.textLabel?.text = "#\(self.results.hashtags[indexPath.row])"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch self.sections[indexPath.section] {
        case .Accounts: return FollowViewCell.rowHeight
        case .Statuses: return UITableViewAutomaticDimension
        case .Hashtags: return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.searchBar.resignFirstResponder()
        
        switch self.sections[indexPath.section] {
        case .Accounts: self.pushAccount(account: self.results.accounts[indexPath.row])
        case .Statuses: self.pushContext(status: self.results.statuses[indexPath.row])
        case .Hashtags: self.pushHashtag(hashtag: self.results.hashtags[indexPath.row])
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
    
    func pushHashtag(hashtag: String) {
        guard let client = GlobalStore.state.auth.client else { return }
        self.performSegue(withIdentifier: "PushHashtagViewController", sender: hashtag)
        GlobalStore.dispatch(SearchState.PollHashtag(client: client, value: hashtag))
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
        case "PushHashtagViewController": do {
            guard let hashtagVC = segue.destination as? HashtagViewController,
                let tag = sender as? String else {
                    segue.destination.dismiss(animated: true, completion: nil)
                    return
            }
            hashtagVC.hashtag = tag
            hashtagVC.title = "#\(tag)"
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
