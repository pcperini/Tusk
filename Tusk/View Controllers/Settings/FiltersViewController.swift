//
//  FiltersViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 9/10/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit

class FiltersViewController: PaginatingTableViewController<Filter>, SubscriptionResponder {
    var filters: [Filter] = []
    lazy var subscriber: Subscriber = Subscriber(state: { $0.filters }, newState: self.newState)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pagingEnabled = false
        
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.subscriber.start()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.subscriber.stop()
    }
    
    func newState(state: FiltersState) {
        self.filters = state.filters
        self.tableView.reloadData()
    }
    
    // MARK: Table View
    override func dataForRowAtIndexPath(indexPath: IndexPath) -> Filter? {
        return self.filters[indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filters.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let filterCell: FilterViewCell = self.tableView.dequeueReusableCell(withIdentifier: "FilterViewCell",
                                                                                  for: indexPath,
                                                                                  usingNibNamed: "FilterViewCell")
        filterCell.filter = self.dataForRowAtIndexPath(indexPath: indexPath)
        return filterCell
    }
}
