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

class AccountViewController: StatusesViewController, SubscriptionResponder {
    private var state: AccountState? {
        guard let accountID = self.account?.id else { return nil }
        return GlobalStore.state.accounts.accountWithID(id: accountID)
    }
    
    lazy var subscriber: Subscriber = Subscriber(state: { $0.accounts.accountWithID(id: self.account!.id)! }, newState: self.newState)
    
    enum Section: Int, CaseIterable {
        case About = 0
        case Stats = 1
        case Statuses = 2
    }
    
    enum Stat: Int, CaseIterable {
        case Statuses = 0
        case Followers = 1
        case Follows = 2
        case Favourites = 3
        
        static func allCases(givenState: AccountState?) -> AllCases {
            guard let state = givenState, state.isActiveAccount else { return Array(self.allCases[0 ..< self.allCases.count - 1]) }
            return self.allCases
        }
    }
    
    var account: AccountType? { didSet { self.updateAccount() } }
    var hasPolledPinnedStatuses: Bool = false
    
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
    
    override var statusesSection: Int { return Section.Statuses.rawValue }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.subscriber.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.subscriber.stop()
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        self.updateNavigationButtons()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftItemsSupplementBackButton = true
        
        self.refreshingEnabled = false
        self.pagingEnabled = false
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

        self.statuses = self.state?.pinnedStatuses ?? []
        if (!self.hasPolledPinnedStatuses) {
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
        var rightButtons: [UIBarButtonItem] = []
        
        guard let activeAccountState = GlobalStore.state.accounts.activeAccount,
            let activeAccount = activeAccountState.account else { return }
        
        if (account.id == activeAccount.id) {
            let rightButton = UIBarButtonItem()
            rightButton.image = UIImage(named: "SettingsButton")
            rightButton.action = #selector(presentSettings(sender:))
            rightButtons.append(rightButton)
        } else if let relationship = self.relationship {
            let followButton = UIBarButtonItem()
            followButton.image = UIImage(named: relationship.following ? "StopFollowingButton" : "FollowButton")
            followButton.tintColor = UIColor(named: relationship.following ? "DestructiveButtonColor" : "DefaultButtonColor")
            followButton.action = #selector(toggleFollowButtonWasPressed(sender:))
            rightButtons.append(followButton)
            
            let mentionButton = UIBarButtonItem()
            mentionButton.image = UIImage(named: "MentionButton")
            mentionButton.action = #selector(presentMentionComposeViewController(sender:))
            rightButtons.append(mentionButton)
        }
        
        rightButtons.forEach { $0.isEnabled = true }
        rightButtons.forEach { $0.target = self }
        
        self.navigationItem.rightBarButtonItems = rightButtons
        if (self.navigationController?.viewControllers.first == self.parent) {
            self.parent?.navigationItem.rightBarButtonItems = rightButtons
        }
    }
    
    func pollPinnedStatuses() {
        guard let client = GlobalStore.state.auth.client, let account = self.account else { return }
        self.hasPolledPinnedStatuses = true
        self.statuses = []
        GlobalStore.dispatch(AccountState.PollPinnedStatuses(client: client, account: account))
    }
    
    func pollRelationship() {
        guard let client = GlobalStore.state.auth.client, let account = self.account else { return }
        self.hasPolledRelationship = true
        GlobalStore.dispatch(AccountState.PollRelationship(client: client, account: account))
    }
    
    func newState(state: AccountState) {
        let newStatuses = state.pinnedStatuses

        self.account = state.account
        self.relationship = state.relationship
        if (self.statuses != newStatuses) {
            self.statuses = newStatuses
            self.tableView.reloadData()
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
        case .Stats: return Stat.allCases(givenState: self.state).count
        case .Statuses: return self.numberOfStatusRows
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { return UITableViewCell() }
        
        switch section {
        case .About: return self.tableView(tableView, cellForAboutSectionRow: indexPath.row)
        case .Stats: return self.tableView(tableView, cellForStatsSectionRow: indexPath.row)
        case .Statuses: do {
            let cell = super.tableView(tableView, cellForRowAt: indexPath)
            cell.selectionStyle = .none
            return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForAboutSectionRow row: Int) -> FieldViewCell {
        guard let account = self.account else { return FieldViewCell() }
        let cell: FieldViewCell = self.tableView.dequeueReusableCell(withIdentifier: "FieldCell",
                                                                     for: IndexPath(row: row, section: Section.About.rawValue),
                                                                     usingNibNamed: "FieldViewCell")
        
        let field = account.fields[row]
        let displayField = account.displayFields[row]

        let name = displayField.name
        let displayValue = displayField.value
        guard let rawValue = NSAttributedString(htmlString: field.value) else { return cell }
        
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
        let cell: FieldViewCell = tableView.dequeueReusableCell(withIdentifier: "FieldCell",
                                                                for: IndexPath(row: row, section: Section.Stats.rawValue),
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
        case .Favourites: do {
            cell.fieldNameLabel.text = "Favs"
            cell.fieldValueTextView.htmlText = "→"
            }
        }

        cell.iconView.image = FieldViewCell.iconForStat(stat: stat)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        switch section {
        case .About: return self.account?.displayFields.count ?? 0 > 0 ? "About" : nil
        case .Stats: return nil
        case .Statuses: return self.statuses.count > 0 ? "Pinned" : nil
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
            case .Favourites: self.pushToFavourites()
            }
            }
        case .Statuses: return
        }
    }
    
    // MARK: Navigation
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
    
    @IBAction func presentMentionComposeViewController(sender: UIBarButtonItem?) {
        self.performSegue(withIdentifier: "PresentComposeViewController", sender: self.account)
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
        case "PresentComposeViewController": do {
            guard let composeContainerVC = segue.destination as? ComposeContainerViewController,
                let composeVC = composeContainerVC.composeViewController,
                let sender = sender as? Account else {
                    segue.destination.dismiss(animated: true, completion: nil)
                    return
                }
            
            composeVC.redraft = StatusPlaceholder(content: "\(sender.handle) ",
                                                  visibility: .private,
                                                  inReplyToID: nil,
                                                  mentions: [])
            }
        default: do {
            super.prepare(for: segue, sender: sender)
            return
            }
        }
    }
}
