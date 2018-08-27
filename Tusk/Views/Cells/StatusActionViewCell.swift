//
//  StatusActionViewCell.swift
//  Tusk
//
//  Created by Patrick Perini on 8/19/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

class StatusActionViewCell: UITableViewCell {
    @IBOutlet var favouriteButton: UIButton!
    var favouritedButtonWasTapped: (() -> Void)? = nil
    
    @IBOutlet var reblogButton: UIButton!
    var reblogButtonWasTapped: (() -> Void)? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
    
    @IBAction func favouriteButtonWasTouchedUpInside(sender: UIButton?) {
        self.favouritedButtonWasTapped?()
    }
    
    @IBAction func reblogButtonWasTouchedUpInside(sender: UIButton?) {
        self.reblogButtonWasTapped?()
    }
}
