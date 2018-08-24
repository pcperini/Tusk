//
//  UITableView+CellNib.swift
//  Tusk
//
//  Created by Patrick Perini on 8/24/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

extension UITableView {
    open func dequeueReusableCell<CellType: UITableViewCell>(withIdentifier identifier: String, forIndexPath indexPath: IndexPath, usingNibNamed nibName: String) -> CellType {        
        guard let cell = self.dequeueReusableCell(withIdentifier: identifier) as? CellType else {
            self.register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: identifier)
            return self.dequeueReusableCell(withIdentifier: identifier, forIndexPath: indexPath, usingNibNamed: nibName)
        }

        return cell
    }
}
