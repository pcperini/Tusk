//
//  TableViewCell.swift
//  Tusk
//
//  Created by Patrick Perini on 8/19/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MGSwipeTableCell

protocol SubviewsBackgroundColorPreservable { var subviews: [UIView] { get } }

class TableViewCell: MGSwipeTableCell {
    @IBInspectable var selectedBackgroundColor: UIColor? {
        didSet {
            let view = UIView()
            view.backgroundColor = self.selectedBackgroundColor
            self.selectedBackgroundView = view
        }
    }

    private var backgroundColoredViewsColors: Dictionary<UIView, UIColor?> = [:]
    @IBOutlet var backgroundColoredViews: [UIView]! = []
    private var allBackgroundColoredViews: [UIView] {
        return self.backgroundColoredViews.reduce([], { (all, view) in
            if (view is SubviewsBackgroundColorPreservable) {
                return all + view.subviews
            } else {
                return all + [view]
            }
        })
    }
    
    func preserveBackgroundColors() {
        self.backgroundColoredViewsColors = self.allBackgroundColoredViews.reduce(Dictionary<UIView, UIColor?>()) { (all, view) in
            all.merging([view: view.backgroundColor]) { (a, b) in a }
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.allBackgroundColoredViews.forEach { (view) in
            view.backgroundColor = self.backgroundColoredViewsColors[view] ?? nil
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.allBackgroundColoredViews.forEach { (view) in
            view.backgroundColor = self.backgroundColoredViewsColors[view] ?? nil
        }
    }
}
