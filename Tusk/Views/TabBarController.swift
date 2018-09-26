//
//  TabBarController.swift
//  Tusk
//
//  Created by Patrick Perini on 9/24/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

class TabBarController: UIViewController {
    enum Edge: String {
        case Top = "Top"
        case Bottom = "Bottom"
        case Left = "Left"
        case Right = "Right"
    }
    
    var edge: Edge = .Bottom {
        didSet { self.contentView?.edge = self.edge }
    }
    @IBInspectable var edgeName: String {
        get { return self.edge.rawValue }
        set { self.edge = Edge(rawValue: newValue) ?? .Bottom }
    }
    
    private var contentView: TabBarView? { return (self.viewIfLoaded as? TabBarView) }
    var tabBar: UIStackView! {
        return self.contentView?.tabBar
    }
    
    @IBOutlet var viewControllers: [UIViewController] = [] {
        didSet { if (self.viewControllers != oldValue) { self.updateTabBar() } }
    }
    var selectedViewController: UIViewController { return self.viewControllers[selectedIndex] }
    var selectedIndex: Int = 0 {
        willSet {
            guard newValue < self.viewControllers.count else {
                fatalError("Selected index \(newValue) out of bounds \(self.viewControllers.count)")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.contentView?.edge = self.edge
    }
    
    private func updateTabBar() {
        // update buttons
        // update container
    }
}

@IBDesignable class TabBarView: View {
    private static let TabBarSize: CGFloat = 44.0
    
    fileprivate var edge: TabBarController.Edge = .Bottom {
        didSet { self.needsUpdateEdges = self.edge != oldValue }
    }
    
    private var contentView: View = View()
    
    private(set) var tabBar: UIStackView = UIStackView()
    private var tabBarContainer: View = View()
    
    private var needsUpdateEdges: Bool = true {
        didSet { self.setNeedsLayout() }
    }
    
    private func resetTabBar() {
        let container = self.tabBarContainer
        container.removeFromSuperview()
        container.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(container)
        
        let tabBar = self.tabBar
        tabBar.removeFromSuperview()
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tabBar)
    }
    
    private func updateTabBar() {
        let container = self.tabBarContainer
        switch self.edge {
        case .Top: self.pinSubview(subview: container,
                                   to: [.top, .left, .right],
                                   withSizes: [.height: TabBarView.TabBarSize + self.safeAreaInsets.top])
        case .Bottom: self.pinSubview(subview: container,
                                      to: [.bottom, .left, .right],
                                      withSizes: [.height: TabBarView.TabBarSize + self.safeAreaInsets.bottom])
        case .Left: self.pinSubview(subview: container,
                                    to: [.top, .left, .bottom],
                                    withSizes: [.width: TabBarView.TabBarSize + self.safeAreaInsets.left])
        case .Right: self.pinSubview(subview: container,
                                     to: [.top, .right, .bottom],
                                     withSizes: [.width: TabBarView.TabBarSize + self.safeAreaInsets.right])
        }
        
        container.setNeedsLayout()
        
        let tabBar = self.tabBar
        container.pinSubview(subview: tabBar,
                             to: [.top, .left, .right, .bottom],
                             withSizes: [:])

        switch self.edge {
        case .Top: tabBar.topConstraint?.constant -= self.safeAreaInsets.top
        case .Bottom: tabBar.bottomConstraint?.constant += self.safeAreaInsets.bottom
        case .Left: tabBar.leftConstraint?.constant += self.safeAreaInsets.left
        case .Right: tabBar.rightConstraint?.constant -= self.safeAreaInsets.right
        }

        tabBar.setNeedsLayout()
    }
    
    private func resetContentView() {
        let contentView = self.contentView
        contentView.removeFromSuperview()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(contentView)
    }
    
    private func updateContentView() {
        let contentView = self.contentView
        let tabBar = self.tabBarContainer
        
        switch self.edge {
        case .Top: do {
            self.pinSubview(subview: contentView,
                            to: [.bottom, .left, .right],
                            withSizes: [:])
            NSLayoutConstraint.activate([contentView.topAnchor.constraint(equalTo: tabBar.bottomAnchor)])
            }
        case .Bottom: do {
            self.pinSubview(subview: contentView,
                            to: [.top, .left, .right],
                            withSizes: [:])
            NSLayoutConstraint.activate([contentView.bottomAnchor.constraint(equalTo: tabBar.topAnchor)])
            }
        case .Left: do {
            self.pinSubview(subview: contentView,
                            to: [.top, .right, .bottom],
                            withSizes: [:])
            NSLayoutConstraint.activate([contentView.leftAnchor.constraint(equalTo: tabBar.rightAnchor)])
            }
        case .Right: do {
            self.pinSubview(subview: contentView,
                            to: [.top, .left, .bottom],
                            withSizes: [:])
            NSLayoutConstraint.activate([contentView.rightAnchor.constraint(equalTo: tabBar.leftAnchor)])
            }
        }
        
        contentView.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.needsUpdateEdges {
            self.resetContentView()
            self.resetTabBar()

            self.updateTabBar()
            self.updateContentView()
            
            self.needsUpdateEdges = false
        }
    }
}
