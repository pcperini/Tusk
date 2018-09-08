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
import SafariServices

class AccountViewController: UITableViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = AccountsState
    private var state: AccountState? {
        guard let accountID = self.account?.id else { return nil }
        return GlobalStore.state.accounts.accountWithID(id: accountID)
    }
    
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
    
    var account: AccountType? { didSet { self.updateAccount() } }
    var pinnedStatuses: [Status]? = nil
    
    private var hasPolledRelationship: Bool = false
    var relationship: Relationship? = nil {
        didSet {
            guard self.relationship != oldValue else { return }
            self.updateAccount()
        }
    }
    
    @IBOutlet var headerImageView: UIImageView!
    @IBOutlet var avatarView: AvatarView!
    @IBOutlet var displayNameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    
    @IBOutlet var followingLabel: UILabel!
    @IBOutlet var relationshipSettingsButton: UIButton!
    @IBOutlet var relationshipHeightConstraints: [ToggleLayoutConstraint]!
    
    @IBOutlet var bioTextView: TextView!
    @IBOutlet var bioTopConstraint: ToggleLayoutConstraint!
    @IBOutlet var bioHeightConstraint: NSLayoutConstraint!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GlobalStore.subscribe(self) { (subscription) in subscription.select { (state) in state.accounts }}
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GlobalStore.unsubscribe(self)
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        self.updateNavigationButtons()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftItemsSupplementBackButton = true
        
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

        self.displayNameLabel.text = account.name
        self.usernameLabel.text = account.handle
        
        self.headerImageView.image = nil
        if let headerURL = URL(string: account.header) {
            self.headerImageView.af_setImage(withURL: headerURL)
        }
        
        self.avatarView.avatarURL = URL(string: account.avatar)
        self.avatarView.badgeType = AvatarView.BadgeType(account: account)
        
        self.bioTextView.htmlText = account.note
        self.bioTopConstraint.toggle(on: !(self.bioTextView.text?.isEmpty ?? true))
        self.bioHeightConstraint.isActive = self.bioTextView.text?.isEmpty ?? true

        self.pinnedStatuses = self.state?.pinnedStatuses
        if (self.pinnedStatuses == nil) {
            self.pollPinnedStatuses()
        }
        
        self.tableView.reloadData()
        self.reloadHeaderView()
        self.navigationItem.title = account.name
        
        guard self.navigationController != nil else { return }
        self.updateNavigationButtons()

        if let relationship = self.relationship {
            self.followingLabel.text = relationship.followedBy ? "Follows you" : "Does not follow you"
        } else if (!self.hasPolledRelationship) {
            self.followingLabel.text = "..."
            self.pollRelationship()
        }
        
        guard let activeAccountState = GlobalStore.state.accounts.activeAccount,
            let activeAccount = activeAccountState.account else { return }
        
        self.relationshipHeightConstraints.forEach { $0.toggle(on: account.id != activeAccount.id) }
    }
    
    func updateNavigationButtons() {
        guard let account = self.account as? Account else { return }
        let rightButton: UIBarButtonItem = UIBarButtonItem()
        let leftButton: UIBarButtonItem = UIBarButtonItem()
        
        guard let activeAccountState = GlobalStore.state.accounts.activeAccount,
            let activeAccount = activeAccountState.account else { return }

        leftButton.isEnabled = true
        rightButton.isEnabled = true
        
        rightButton.target = self
        leftButton.target = self
        
        if (account.id == activeAccount.id) {
            rightButton.image = UIImage(named: "SettingsButton")
            rightButton.action = #selector(presentSettings(sender:))
            
            leftButton.image = UIImage(named: "FavouriteButton")
            leftButton.action = #selector(favouritesButtonWasPressed(sender:))
        } else if let relationship = self.relationship {
            rightButton.image = UIImage(named: relationship.following ? "StopFollowingButton" : "FollowButton")
            rightButton.tintColor = UIColor(named: relationship.following ? "DestructiveButtonColor" : "DefaultButtonColor")
            rightButton.action = #selector(toggleFollowButtonWasPressed(sender:))
            
            leftButton.image = nil
        }
        
        self.navigationItem.rightBarButtonItem = rightButton
        if (self.navigationController?.viewControllers.first == self.parent) {
            self.parent?.navigationItem.rightBarButtonItem = rightButton
            self.parent?.navigationItem.leftBarButtonItem = leftButton
        }
    }
    
    func pollPinnedStatuses() {
        guard let client = GlobalStore.state.auth.client, let account = self.account else { return }
        self.pinnedStatuses = []
        GlobalStore.dispatch(AccountState.PollPinnedStatuses(client: client, account: account))
    }
    
    func pollRelationship() {
        guard let client = GlobalStore.state.auth.client, let account = self.account else { return }
        self.hasPolledRelationship = true
        GlobalStore.dispatch(AccountState.PollRelationship(client: client, account: account))
    }
    
    func newState(state: AccountsState) {
        guard let accountID = self.account?.id, let state = state.accountWithID(id: accountID) else { return }
        let newStatuses = state.pinnedStatuses

        DispatchQueue.main.async {
            self.account = state.account
            self.relationship = state.relationship
            if (self.pinnedStatuses != newStatuses) {
                self.pinnedStatuses = newStatuses
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func toggleFollowButtonWasPressed(sender: UIBarButtonItem?) {
        guard let client = GlobalStore.state.auth.client, let account = self.account else { return }
        GlobalStore.dispatch(AccountState.ToggleFollowing(client: client, account: account))
    }
    
    @IBAction func favouritesButtonWasPressed(sender: UIBarButtonItem?) {
        self.pushToFavourites()
    }
    
    // MARK: Table View
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
        let cell: FieldViewCell = self.tableView.dequeueReusableCell(withIdentifier: "FieldCell",
                                                                     for: IndexPath(row: row, section: Section.About.rawValue),
                                                                     usingNibNamed: "FieldViewCell")
        
        let field = account.fields[row]
        let displayField = account.displayFields[row]

        guard let name = displayField["name"],
            let displayValue = displayField["value"],
            let rawValue = NSAttributedString(htmlString: field["value"]!) else { return cell }
        let plainValue = rawValue.string
        
        cell.fieldNameLabel.text = name
        cell.fieldValueTextView.htmlText = displayValue
        cell.selectionStyle = .none
        
        if let link = rawValue.allAttributes[.link] as? URL {
            cell.selectionStyle = .default
            cell.url = link
        }
        
        cell.iconView.image = FieldViewCell.iconForCustomField(fieldName: name, fieldValue: plainValue)
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForStatsSectionRow row: Int) -> FieldViewCell {
        guard let account = self.account else { return FieldViewCell() }
        guard let stat = Stat(rawValue: row) else { return FieldViewCell() }
        let cell: FieldViewCell = self.tableView.dequeueReusableCell(withIdentifier: "FieldCell",
                                                                     for: IndexPath(row: row, section: Section.About.rawValue),
                                                                     usingNibNamed: "FieldViewCell")
        
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
        let cell: StatusViewCell = self.tableView.dequeueReusableCell(withIdentifier: "Status",
                                                                      for: IndexPath(row: row, section: Section.Statuses.rawValue),
                                                                      usingNibNamed: "StatusViewCell")
        
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }
        switch section {
        case .About: do {
            guard let cell = self.tableView.cellForRow(at: indexPath) as? FieldViewCell else { break }
            guard let url = cell.url else { break }
            self.openURL(url: url)
            }
        case .Stats: do {
            guard let stat = Stat(rawValue: indexPath.row) else { break }
            switch stat {
            case .Statuses: self.pushToStatuses()
            case .Followers: self.pushToFollowers()
            case .Follows: self.pushToFollows()
            }
            }
        default: break
        }
    }
    
    // MARK: Navigation
    func openURL(url: URL) {
        UIApplication.shared.open(url, options: [:]) { (success) in
            guard let indexPath = self.tableView.indexPathForSelectedRow else { return }
            self.tableView.deselectRow(at: indexPath, animated: !success)
        }
    }
    
    func pushToStatuses() {
        guard let account = self.account, let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(AccountState.PollStatuses(client: client, account: account))
        self.performSegue(withIdentifier: "PushAccountStatusesViewController", sender: self.account)
    }
    
    func pushToFollowers() {
        guard let account = self.account, let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(AccountState.PollFollowers(client: client, account: account))
        self.performSegue(withIdentifier: "PushFollowsViewController", sender: (self.account, RelationshipDirection.Follower))
    }
    
    func pushToFollows() {
        guard let account = self.account, let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(AccountState.PollFollowing(client: client, account: account))
        self.performSegue(withIdentifier: "PushFollowsViewController", sender: (self.account, RelationshipDirection.Following))
    }
    
    func pushToFavourites() {
        self.performSegue(withIdentifier: "PushFavouritesViewController", sender: nil)
    }
    
    @IBAction func presentSettings(sender: UIBarButtonItem?) {
        self.performSegue(withIdentifier: "PresentSettingsViewController", sender: nil)
    }
    
    @IBAction func presentRelationshipSettings(sender: UIButton?) {
        guard let account = self.account,
            let relationship = self.relationship,
            let client = GlobalStore.state.auth.client else { return }
        
        let settingsPicker = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let handle = { (action: Action) in
            return { (_: UIAlertAction) in
                GlobalStore.dispatch(action)
            }
        }

        if (relationship.following) {
            let muteNotificationsAction = UIAlertAction(title: relationship.showingReblogs ? "Hide Reposts" : "Show Reposts",
                                                        style: .default,
                                                        handler: handle(AccountState.ToggleReposts(client: client, account: account)))
            settingsPicker.addAction(muteNotificationsAction)
            let muteAction = UIAlertAction(title: relationship.muting ? "Unmute" : "Mute",
                                           style: .default,
                                           handler: handle(AccountState.ToggleMuting(client: client, account: account)))
            settingsPicker.addAction(muteAction)
        }
        
        let followAction = UIAlertAction(title: relationship.following ? "Unfollow" : (relationship.requested ? "Requested" : "Follow"),
                                         style: relationship.following ? .destructive : .default,
                                         handler: handle(AccountState.ToggleFollowing(client: client, account: account)))
        followAction.isEnabled = !relationship.requested
        settingsPicker.addAction(followAction)
        
        let blockAction = UIAlertAction(title: relationship.blocking ? "Unblock" : "Block",
                                        style: relationship.blocking ? .default : .destructive,
                                        handler: handle(AccountState.ToggleBlocking(client: client, account: account)))
        settingsPicker.addAction(blockAction)
        settingsPicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(settingsPicker, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch segue.identifier {
        case "PushAccountStatusesViewController": do {
            guard let accountStatusesVC = segue.destination as? AccountStatusesViewController, let account = sender as? Account else {
                segue.destination.dismiss(animated: true, completion: nil)
                return
            }
            
            accountStatusesVC.account = account
            }
        case "PushFollowsViewController": do {
            guard let accountStatusesVC = segue.destination as? FollowsViewController,
                let sender = sender as? (Account?, RelationshipDirection),
                let account = sender.0 else {
                segue.destination.dismiss(animated: true, completion: nil)
                return
            }
            
            accountStatusesVC.account = account
            accountStatusesVC.relationshipDirection = sender.1
            }
        default: return
        }
    }
}
