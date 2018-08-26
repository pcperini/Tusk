//
//  TableViewMergeHandler.swift
//  Tusk
//
//  Created by Patrick Perini on 8/26/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

struct TableViewMergeHandler<DataType> {
    private struct DiffState {
        let removed: [(Int, DataType)]
        let inserted: [(Int, DataType)]
        
        var removedIndexPaths: [IndexPath] {
            return self.removed.map { IndexPath(row: $0.0, section: 0) }
        }
        
        var insertedIndexPaths: [IndexPath] {
            return self.inserted.map { IndexPath(row: $0.0, section: 0) }
        }
    }
    
    let tableView: UITableView
    var data: [DataType]? = nil
    var dataComparator: (DataType, DataType) -> Bool
    
    func mergeData(data newData: [DataType], preservingSelection: Bool = true, preservingPosition: Bool = true) {
        guard let oldData = self.data, preservingSelection && preservingPosition else {
            self.tableView.reloadData()
            return
        }
        
        let selectedIndex = self.tableView.indexPathForSelectedRow?.row
        let selectedItem =  selectedIndex == nil ? nil : oldData[selectedIndex!]
        
        let firstVisibleIndex
        
        let diffState = TableViewMergeHandler.diff(old: oldData, new: newData, compare: self.dataComparator)
        
        self.tableView.beginUpdates()
        self.tableView.deleteRows(at: diffState.removedIndexPaths, with: .automatic)
        self.tableView.insertRows(at: diffState.insertedIndexPaths, with: .automatic)
        self.tableView.endUpdates()
    }
    
    private static func diff(old: [DataType], new: [DataType], compare: (DataType, DataType) -> Bool) -> DiffState {
        if (old.isEmpty) { return DiffState(removed: [], inserted: Array(new.enumerated())) }
        if (new.isEmpty) { return DiffState(removed: Array(new.enumerated()), inserted: []) }
        
        var removed: [(Int, DataType)] = []
        var inserted: [(Int, DataType)] = []
        var seen: [DataType] = []
        
        outer: for (oldIndex, oldData) in old.enumerated() {
            for newData in new {
                if compare(oldData, newData) {
                    seen.append(newData)
                    continue outer
                }
            }
            
            removed.append((oldIndex, oldData))
        }
        
        for (newIndex, newData) in new.enumerated() {
            if (seen.contains(where: { compare($0, newData) })) { continue }
            inserted.append((newIndex, newData))
        }
        
        return DiffState(removed: removed, inserted: inserted)
    }
}
