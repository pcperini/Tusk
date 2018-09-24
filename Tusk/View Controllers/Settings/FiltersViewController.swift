//
//  FiltersViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 9/10/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit

class FiltersViewController: UITableViewController, SubscriptionResponder {
    var filters: [FilterType] = []
    lazy var subscriber: Subscriber = Subscriber(state: { $0.filters }, newState: self.newState)
    lazy private var tableMergeHandler: TableViewMergeHandler<Filter> = TableViewMergeHandler(tableView: self.tableView,
                                                                                              section: 0,
                                                                                              data: nil,
                                                                                              selectedElement: nil,
                                                                                              dataComparator: self.filtersAreEqual)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let addButton = UIBarButtonItem(image: UIImage(named: "AddButton"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(addButtonWasPressed(sender:)))
        self.navigationItem.rightBarButtonItem = addButton
        
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
        self.tableMergeHandler.mergeData(data: state.filters, animated: true)
    }
    
    func filtersAreEqual(lhs: FilterType, rhs: FilterType) -> Bool {
        return (
            lhs.id == rhs.id &&
            lhs.phrase == rhs.phrase &&
            lhs.content == rhs.content
        )
    }
    
    // MARK: Responders
    @objc func addButtonWasPressed(sender: UIBarButtonItem?) {
        self.filters.insert(FilterPlaceholder(phrase: ""), at: 0)
        guard let tableView = self.tableView as? TableView else { return }
        tableView.appendBatchUpdates({ tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .none) })
    }
    
    // MARK: Table View
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filters.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let filterCell: FilterViewCell = self.tableView.dequeueReusableCell(withIdentifier: "FilterViewCell",
                                                                            for: indexPath,
                                                                            usingNibNamed: "FilterViewCell")
        let filter = self.filters[indexPath.row]
        
        filterCell.filter = filter
        filterCell.filterWasUpdated = { (phrase: String) in
            guard let client = GlobalStore.state.auth.client else { return }
            let id = filter.id == NSNotFound ? nil : filter.id
            GlobalStore.dispatch(FiltersState.SaveFilter(client: client,
                                                         phrase: phrase,
                                                         id: id))
            if id == nil {
                self.filters.remove(at: 0)
                self.tableView.reloadData()
            }
        }
        
        filterCell.filterDeleteWasTriggered = {
            guard let client = GlobalStore.state.auth.client else { return }
            GlobalStore.dispatch(FiltersState.DeleteFilter(client: client,
                                                           id: filter.id))
        }
        
        return filterCell
    }
}
