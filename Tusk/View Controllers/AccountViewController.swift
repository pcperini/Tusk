//
//  AccountViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/14/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit
import ReSwift

class AccountViewController: UITableViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = AccountState
    
    enum Section: Int {
        case About = 0
        case Stats = 1
        case Statuses = 2
        
        static var count = 3
    }
    
    enum Stats: Int {
        case Statuses = 0
        case Follows = 1
        case Followers = 2
        
        static var count = 3
    }
    
    var account: Account? { didSet { self.updateAccount() } }
    var pinnedStatuses: [Status] = []
    
    @IBOutlet var headerImageView: UIImageView!
    @IBOutlet var avatarView: ImageView!
    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var bioTextView: TextView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GlobalStore.subscribe(self) { (subscription) in subscription.select { (state) in state.account } }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GlobalStore.unsubscribe(self)
    }
    
    override func viewDidLoad() {
        self.updateAccount()
        
        // TODO: Fix this magic number
        if let headerView = self.tableView.tableHeaderView {
            var frame = headerView.frame
            frame.size.height = headerView.subviews.last!.systemLayoutSizeFitting(UILayoutFittingExpandedSize).height + 30
            headerView.frame = frame
            self.tableView.reloadData()
        }
    }
    
    func updateAccount() {
        guard let account = self.account else { return }
        self.parent?.navigationItem.title = account.name
        
        self.headerImageView.af_setImage(withURL: URL(string: account.header)!)
        self.avatarView.af_setImage(withURL: URL(string: account.avatar)!)
        self.displayNameLabel.text = account.name
        self.usernameLabel.text = account.handle
        self.bioTextView.text = account.plainNote
        
        self.pollPinnedStatuses()
    }
    
    func pollPinnedStatuses() {
        guard let client = GlobalStore.state.auth.client else { return }
        guard let account = self.account else { return }
        
        GlobalStore.dispatch(AccountState.PollAccountPinnedStatuses(client: client, account: account))
    }
    
    func newState(state: AccountState) {
        guard let account = self.account else { return }
        guard let newStatuses = state.pinnedStatuses[account] else { return }
        
        DispatchQueue.main.async {
            if (self.pinnedStatuses != newStatuses) {
                self.pinnedStatuses = newStatuses
                self.tableView.reloadData()
            }
        }
    }
    
    // UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let account = self.account else { return 0 }
        guard let section = Section(rawValue: section) else { return 0 }
        
        switch section {
        case .About: return account.fields.count
        case .Stats: return Stats.count
        case .Statuses: return self.pinnedStatuses.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { return UITableViewCell() }
        
        switch section {
        case .About: return self.tableView(tableView, cellForAboutSectionRow: indexPath.row)
        case .Stats: return self.tableView(tableView, cellForStatsSectionRow: indexPath.row)
        case .Statuses: return self.tableView(tableView, cellForStatusesSectionRow: indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForAboutSectionRow row: Int) -> FieldViewCell {
        guard let account = self.account else { return FieldViewCell() }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FieldCell") as? FieldViewCell else {
            return FieldViewCell()
        }
        
        cell.fieldNameLabel.text = account.fields[row]["name"]
        cell.fieldValueTextView.text = account.fields[row]["value"]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForStatsSectionRow row: Int) -> FieldViewCell {
        guard let account = self.account else { return FieldViewCell() }
        guard let stat = Stats(rawValue: row) else { return FieldViewCell() }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FieldCell") as? FieldViewCell else {
            return FieldViewCell()
        }
        
        let format = { (n: Int) in NumberFormatter.localizedString(from: NSNumber(value: n), number: .decimal) }

        switch stat {
        case .Statuses: do {
            cell.fieldNameLabel.text = "Posts"
            cell.fieldValueTextView.text = format(account.statusesCount)
            }
        case .Follows: do {
            cell.fieldNameLabel.text = "Following"
            cell.fieldValueTextView.text = format(account.followingCount)
            }
        case .Followers: do {
            cell.fieldNameLabel.text = "Followers"
            cell.fieldValueTextView.text = format(account.followersCount)
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForStatusesSectionRow row: Int) -> StatusViewCell {
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: "Status") as? StatusViewCell else {
            self.tableView.register(UINib(nibName: "StatusViewCell", bundle: nil), forCellReuseIdentifier: "Status")
            return self.tableView(tableView, cellForStatusesSectionRow: row)
        }
        
        cell.status = self.pinnedStatuses[row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        switch section {
        case .About: return "About"
        case .Stats: return nil
        case .Statuses: return "Pinned"
        }
    }
}
