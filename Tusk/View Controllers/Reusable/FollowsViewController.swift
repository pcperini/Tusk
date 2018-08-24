//
//  FollowsViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/22/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit
import ReSwift

enum RelationshipDirection: String {
    case Follower = "Followers"
    case Following = "Following"
}

class FollowsViewController: PaginatingTableViewController, StoreSubscriber {
    typealias StoreSubscriberStateType = AccountState
    
    var relationshipDirection: RelationshipDirection = .Follower
    var account: Account!
    var follows: [Account] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        GlobalStore.subscribe(self) { (subscription) in subscription.select { (state) in state.accounts.accountWithID(id: self.account.id)! } }
        
        self.navigationItem.title = self.relationshipDirection.rawValue
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GlobalStore.unsubscribe(self)
    }
    
    func newState(state: StoreSubscriberStateType) {
        DispatchQueue.main.async {
            switch self.relationshipDirection {
            case .Follower: self.updateFollows(follows: state.followers)
            case .Following: self.updateFollows(follows: state.following)
            }
        }
    }
    
    func updateFollows(follows: [Account]) {
        if (follows != self.follows) {
            self.follows = follows
            self.tableView.reloadData()
        }
    }
    
    func pollFollowers(pageDirection: PageDirection = .Reload) {
        guard let client = GlobalStore.state.auth.client else { return }
        
        let possibleAction: Action?
        switch self.relationshipDirection {
        case .Follower: do {
            switch pageDirection {
            case .NextPage: possibleAction = AccountState.PollOlderFollowers(client: client, account: self.account)
            case .PreviousPage: possibleAction = AccountState.PollNewerFollowers(client: client, account: self.account)
            case .Reload: possibleAction = AccountState.PollFollowers(client: client, account: self.account)
            }
            }
        case .Following: do {
            switch pageDirection {
            case .NextPage: possibleAction = AccountState.PollOlderFollowing(client: client, account: self.account)
            case .PreviousPage: possibleAction = AccountState.PollNewerFollowing(client: client, account: self.account)
            case .Reload: possibleAction = AccountState.PollFollowing(client: client, account: self.account)
            }
            }
        }
        
        guard let action = possibleAction else { return }
        GlobalStore.dispatch(action)
    }
    
    // Table View Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.follows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // FIXME
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FollowCellView", for: indexPath) as? FollowViewCell else {
            return UITableViewCell()
        }
        
        let follow = self.follows[indexPath.row]
        cell.avatarView.avatarURL = URL(string: follow.avatar)
        cell.avatarView.badgeType = AvatarView.BadgeType(account: follow)
        cell.displayNameLabel.text = follow.name
        cell.usernameLabel.text = follow.handle
        cell.detailLabel.text = follow.behaviorTidbit
        cell.preserveBackgroundColors()
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let account = self.follows[indexPath.row]
        self.pushToAccount(account: account)
    }
    
    // Paging
    override func refreshControlBeganRefreshing() {
        super.refreshControlBeganRefreshing()
        self.pollFollowers(pageDirection: .PreviousPage)
    }
    
    override func pageControlBeganRefreshing() {
        super.pageControlBeganRefreshing()
        self.pollFollowers(pageDirection: .NextPage)
    }
    
    // Navigation
    func pushToAccount(account: Account) {
        self.performSegue(withIdentifier: "PushAccountViewController", sender: account)
        
        guard let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(AccountState.PollAccount(client: client, account: account))
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
