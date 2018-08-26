//
//  TableViewMergeHandler.swift
//  Tusk
//
//  Created by Patrick Perini on 8/26/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

struct TableViewMergeHandler<DataType: Comparable> {
    private struct DiffState {
        let removed: [(Int, DataType)]
        let inserted: [(Int, DataType)]
        let common: [(Int, DataType)]
        
        var removedIndexPaths: [IndexPath] { return self.indexPathsForDiffSet(diffSet: self.removed) }
        var insertedIndexPaths: [IndexPath] { return self.indexPathsForDiffSet(diffSet: self.inserted) }
        var commonIndexPaths: [IndexPath] { return self.indexPathsForDiffSet(diffSet: self.common) }
        
        var isEmpty: Bool { return self.removed.isEmpty && self.inserted.isEmpty && self.common.isEmpty }
        
        func indexPathsForDiffSet(diffSet: [(Int, DataType)]) -> [IndexPath] {
            return diffSet.map { IndexPath(row: $0.0, section: 0) }
        }
    }
    
    let tableView: UITableView
    
    var data: [DataType]? = nil
    var selectedElement: DataType? = nil
    
    var dataComparator: (DataType, DataType) -> Bool
    
    mutating func mergeData(data newData: [DataType]) {
        let tableView = self.tableView
        
        defer { self.data = newData }
        guard let oldData = self.data, !oldData.isEmpty else {
            tableView.reloadData()
            return
        }

        let diffState = TableViewMergeHandler.diff(old: oldData, new: newData, compare: self.dataComparator)
        if (diffState.isEmpty) {
            return
        }
        
        var reloadRows = diffState.commonIndexPaths
        if let selectedIndexPaths = tableView.indexPathsForSelectedRows,
            let reloadSelectedPath = selectedIndexPaths.first(where: { reloadRows.contains($0) }) {
            reloadRows.append(IndexPath(row: reloadSelectedPath.row + 1, section: reloadSelectedPath.section))
        }
        
        let firstVisibleIndex = tableView.indexPathsForVisibleRows?.first?.row ?? 0
        let firstVisibleElement = oldData[firstVisibleIndex]
        let firstVisibleNewIndex = newData.index(of: firstVisibleElement) ?? 0
        
        UIView.performWithoutAnimation {
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: diffState.removedIndexPaths, with: .none)
            self.tableView.insertRows(at: diffState.insertedIndexPaths, with: .none)
            self.tableView.reloadRows(at: reloadRows, with: .none)
            self.tableView.endUpdates()
            
            if (!diffState.inserted.isEmpty) {
                tableView.scrollToRow(at: IndexPath(row: firstVisibleNewIndex, section: 0),
                                      at: .top,
                                      animated: false)
            }
        }
    }
    
    private static func diff(old: [DataType], new: [DataType], compare: (DataType, DataType) -> Bool) -> DiffState {
        if (old.isEmpty) { return DiffState(removed: [], inserted: Array(new.enumerated()), common: []) }
        if (new.isEmpty) { return DiffState(removed: Array(new.enumerated()), inserted: [], common: []) }
        
        var removed: [(Int, DataType)] = []
        var inserted: [(Int, DataType)] = []
        var common: [(Int, DataType)] = []
        var seen: [DataType] = []
        
        outer: for (oldIndex, oldData) in old.enumerated() {
            for (newIndex, newData) in new.enumerated() {
                 if compare(oldData, newData) {
                    seen.append(newData)
                    continue outer
                 } else if (oldData == newData) {
                    common.append((newIndex, newData))
                    seen.append(newData)
                    continue outer
                 }
            }
            
            removed.append((oldIndex, oldData))
        }
        
        for (newIndex, newData) in new.enumerated() {
            if (seen.contains(where: { $0 == newData })) { continue }
            inserted.append((newIndex, newData))
        }
        
        return DiffState(removed: removed, inserted: inserted, common: common)
    }
}
