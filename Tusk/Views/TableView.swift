//
//  TableView.swift
//  Tusk
//
//  Created by Patrick Perini on 9/12/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

class TableView: UITableView {
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
}
