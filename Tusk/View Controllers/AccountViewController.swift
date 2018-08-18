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
    private var state: AccountState { return GlobalStore.state.account }
    
    enum Section: Int, CaseIterable {
        case About = 0
        case Stats = 1
        case Statuses = 2
    }
    
    enum Stat: Int, CaseIterable {
        case Statuses = 0
        case Followers = 1
        case Follows = 2
    }
    
    var account: Account? { didSet { if (oldValue != self.account) { self.updateAccount() } } }
    var pinnedStatuses: [Status]? = nil
    
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
        super.viewDidLoad()
        self.updateAccount()
    }
    
    func reloadHeaderView() {
        if let headerView = self.tableView.tableHeaderView {
            DispatchQueue.main.async {
                var frame = headerView.frame
                
                headerView.setNeedsLayout()
                headerView.layoutIfNeeded()
                
                frame.size.height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
                headerView.frame = frame
                self.tableView.tableHeaderView = headerView
            }
        }
    }
    
    func updateAccount() {
        guard let account = self.account else { return }
        guard self.view != nil else { return }
        
        self.parent?.navigationItem.title = account.name

        self.headerImageView.af_setImage(withURL: URL(string: account.header)!)
        self.avatarView.af_setImage(withURL: URL(string: account.avatar)!)
        self.displayNameLabel.text = account.name
        self.usernameLabel.text = account.handle
        self.bioTextView.htmlText = account.note

        self.pinnedStatuses = GlobalStore.state.account.pinnedStatuses[account]
        if (self.pinnedStatuses == nil) {
            self.pollPinnedStatuses()
        }
        
        self.tableView.reloadData()
        self.reloadHeaderView()
        self.navigationItem.title = account.displayName
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem()
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        
        guard let activeAccount = self.state.activeAccount else { return }
        let image: UIImage?
        if (account == activeAccount) {
            image = UIImage(named: "SettingsButton")
        } else if (self.state.following[activeAccount]?.contains(account) ?? false) {
            image = UIImage(named: "StopFollowingButton")
        } else {
            image = UIImage(named: "FollowButton")
        }
        
        self.navigationItem.rightBarButtonItem?.image = image
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
        return Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let account = self.account else { return 0 }
        guard let section = Section(rawValue: section) else { return 0 }
                
        switch section {
        case .About: return account.displayFields.count
        case .Stats: return Stat.allCases.count
        case .Statuses: return self.pinnedStatuses?.count ?? 0
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
        let cell = (tableView.dequeueReusableCell(withIdentifier: "FieldCell", for: IndexPath(row: row, section: Section.About.rawValue)) as? FieldViewCell) ?? FieldViewCell()

        guard let name = account.displayFields[row]["name"], let value = account.displayFields[row]["value"] else { return FieldViewCell() }

        cell.fieldNameLabel.text = name
        cell.fieldValueTextView.htmlText = value

        cell.iconView.image = FieldViewCell.iconForCustomField(fieldName: name, fieldValue: value)

        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForStatsSectionRow row: Int) -> FieldViewCell {
        guard let account = self.account else { return FieldViewCell() }
        guard let stat = Stat(rawValue: row) else { return FieldViewCell() }
        let cell = (tableView.dequeueReusableCell(withIdentifier: "FieldCell", for: IndexPath(row: row, section: Section.About.rawValue)) as? FieldViewCell) ?? FieldViewCell()
        
        let format = { (n: Int) in NumberFormatter.localizedString(from: NSNumber(value: n), number: .decimal) }

        switch stat {
        case .Statuses: do {
            cell.fieldNameLabel.text = "Posts"
            cell.fieldValueTextView.htmlText = format(account.statusesCount)
            }
        case .Follows: do {
            cell.fieldNameLabel.text = "Following"
            cell.fieldValueTextView.htmlText = format(account.followingCount)
            }
        case .Followers: do {
            cell.fieldNameLabel.text = "Followers"
            cell.fieldValueTextView.htmlText = format(account.followersCount)
            }
        }

        cell.iconView.image = FieldViewCell.iconForStat(stat: stat)
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForStatusesSectionRow row: Int) -> StatusViewCell {
        guard let pinnedStatuses = self.pinnedStatuses else { return StatusViewCell() }
        guard let cell = self.tableView.dequeueReusableCell(withIdentifier: "Status") as? StatusViewCell else {
            self.tableView.register(UINib(nibName: "StatusViewCell", bundle: nil), forCellReuseIdentifier: "Status")
            return self.tableView(tableView, cellForStatusesSectionRow: row)
        }
        
        cell.status = pinnedStatuses[row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        switch section {
        case .About: return self.account?.displayFields.count ?? 0 > 0 ? "About" : nil
        case .Stats: return nil
        case .Statuses: return self.pinnedStatuses?.count ?? 0 > 0 ? "Pinned" : nil
        }
    }
}
