//
//  UITableView+Visibility.swift
//  Tusk
//
//  Created by Patrick Perini on 9/1/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

extension UITableView {
    func fullyVisibleIndexPaths() -> [IndexPath] {
        return (self.indexPathsForVisibleRows ?? []).filter { (indexPath) in
            let rect = self.rectForRow(at: indexPath)
            return self.bounds.contains(rect)
        }
    }
}
