//
//  UITableView+CellNib.swift
//  Tusk
//
//  Created by Patrick Perini on 8/24/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

extension UITableView {
    open func dequeueReusableCell<CellType: UITableViewCell>(withIdentifier identifier: String, for indexPath: IndexPath?, usingNibNamed nibName: String) -> CellType {
        self.register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: identifier)
        if let indexPath = indexPath {
            return self.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! CellType
        } else {
            return self.dequeueReusableCell(withIdentifier: identifier) as! CellType
        }
    }
}

extension UICollectionView {
    open func dequeueReusableCell<CellType: UICollectionViewCell>(withReuseIdentifier identifier: String, for indexPath: IndexPath, usingNibNamed nibName: String) -> CellType {
        self.register(UINib(nibName: nibName, bundle: nil), forCellWithReuseIdentifier: identifier)
        return self.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! CellType
    }
}

extension UINib {
    class func view<ViewType: UIView>(nibName: String) -> ViewType? {
        let topLevel = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)
        return topLevel?.first as? ViewType
    }
}
