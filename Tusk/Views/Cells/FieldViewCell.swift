//
//  FieldCellView.swift
//  Tusk
//
//  Created by Patrick Perini on 8/14/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

class FieldViewCell: UITableViewCell {
    @IBOutlet var iconView: UIImageView!
    @IBOutlet var fieldNameLabel: UILabel!
    @IBOutlet var fieldValueTextView: TextView!
    
    static func iconForStat(stat: AccountViewController.Stat) -> UIImage? {
        switch stat {
        case .Statuses: return UIImage(named: "Statuses")
        case .Followers: return UIImage(named: "Followers")
        case .Follows: return UIImage(named: "Follows")
        }
    }
}
