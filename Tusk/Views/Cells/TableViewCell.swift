//
//  TableViewCell.swift
//  Tusk
//
//  Created by Patrick Perini on 8/19/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {
    @IBInspectable var selectedBackgroundColor: UIColor? {
        didSet {
            let view = UIView()
            view.backgroundColor = self.selectedBackgroundColor
            self.selectedBackgroundView = view
        }
    }

    @IBOutlet var backgroundColoredViews: [UIView]! = []
    private var backgroundColoredViewsColors: Dictionary<UIView, UIColor?> = [:]
    
    func preserveBackgroundColors() {
        self.backgroundColoredViewsColors = self.backgroundColoredViews.reduce(Dictionary<UIView, UIColor?>()) { (all, view) in
            all.merging([view: view.backgroundColor]) { (a, b) in a }
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.backgroundColoredViews.forEach { (view) in
            view.backgroundColor = self.backgroundColoredViewsColors[view] ?? nil
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.backgroundColoredViews.forEach { (view) in
            view.backgroundColor = self.backgroundColoredViewsColors[view] ?? nil
        }
    }
}
