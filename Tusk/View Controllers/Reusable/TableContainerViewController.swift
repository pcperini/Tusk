//
//  TableContainerViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/21/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

class TableContainerViewController: UIViewController {
    var tableViewController: UITableViewController? {
        return self.childViewControllers.filter({ (child) in
            child is UITableViewController
        }).first as? UITableViewController
    }
}
