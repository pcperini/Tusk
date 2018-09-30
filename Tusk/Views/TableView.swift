//
//  TableView.swift
//  Tusk
//
//  Created by Patrick Perini on 9/12/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

class TableView: UITableView {
    private var cellHeights: [AnyHashable: CGFloat] = [:]
    private var updateQueue: [((() -> Void), ((Bool) -> Void)?)] = [] {
        didSet {
            if oldValue.isEmpty {
                self.performNextBatchUpdates()
            }
        }
    }

    func appendBatchUpdates(_ updates: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        self.updateQueue.append((updates, completion))
    }
 
    private func performNextBatchUpdates() {
        guard !self.updateQueue.isEmpty else { return }
        
        let next = self.updateQueue.removeFirst()
        self.performBatchUpdates(next.0) { (completed) in
            next.1?(completed)
            self.performNextBatchUpdates()
        }
    }

    func heightForCellWithID<CellType: UITableViewCell>(id: AnyHashable,
                                                        nibName: String,
                                                        configurator: ((CellType) -> Void)? = nil) -> CGFloat {
        if let height = self.cellHeights[id] {
            return height
        }
        
        guard let cell: CellType = UINib.view(nibName: nibName) else { return UITableViewAutomaticDimension }
        
        configurator?(cell)
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        let size = CGSize(width: cell.frame.width, height: UILayoutFittingCompressedSize.height)
        let height = cell.systemLayoutSizeFitting(size).height
        self.cellHeights[id] = height
        
        return height
    }
}
