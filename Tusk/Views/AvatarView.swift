//
//  AvatarView.swift
//  Tusk
//
//  Created by Patrick Perini on 8/23/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit

@IBDesignable class AvatarView: UIView, SubviewsBackgroundColorPreservable {
    enum BadgeType: String {
        case None = "None"
        case Bot = "Bot"
        case Locked = "Locked"
        case TuskDev = "TuskDev"
        
        fileprivate var image: UIImage? {
            if (self == .None) { return nil }
            return UIImage(named: "\(self.rawValue)Badge")
        }
        
        fileprivate var color: UIColor? {
            if (self == .None) { return nil }
            return UIColor(named: "\(self.rawValue)Color")
        }
        
        fileprivate var edgeInsets: UIEdgeInsets {
            switch self {
            case .None: return .zero
            case .TuskDev: return UIEdgeInsets(top: 10, left: 10, bottom: 8, right: 8)
            default: return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            }
        }
        
        init(account: Account) {
            if (account.locked) { self = .Locked }
            else if (account.bot ?? false) { self = .Bot }
            else if (Bundle.main.developers.contains(account.username)) { self = .TuskDev }
            else { self = .None }
        }
    }
    
    @IBInspectable var showsBadge: Bool = true { didSet { self.setNeedsLayout() } }
    @IBInspectable var borderWidth: CGFloat = 1.0 { didSet { self.setNeedsLayout() } }
    @IBInspectable var borderColor: UIColor = .clear { didSet { self.setNeedsLayout() } }
    
    var avatarURL: URL? = nil { didSet { self.setNeedsLayout(); self.layoutIfNeeded() } }
    var badgeType: BadgeType = .None { didSet { self.setNeedsLayout(); self.layoutIfNeeded() } }
    
    private var lastAvatarURL: URL? = nil
    
    private var imageView: ImageView
    private var badgeView: ImageView
    
    required init?(coder aDecoder: NSCoder) {
        self.imageView = ImageView()
        self.badgeView = ImageView()
        super.init(coder: aDecoder)
        
        self.addSubview(self.imageView)
        self.addSubview(self.badgeView)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.subviews.forEach { (sv) in sv.translatesAutoresizingMaskIntoConstraints = false }
        
        self.addConstraints(self.constraints(pinning: [.top, .bottom, .left, .right], to: self.imageView))
        self.imageView.round = true
        self.imageView.contentMode = .scaleAspectFit
        
        self.addConstraints(self.constraints(pinning: [.bottom: -2, .right: -5], to: self.badgeView))
        self.addConstraints(self.ratioConstraints(pinning: [.width: 0.5, .height: 0.5], to: self.badgeView))
        self.badgeView.round = true
        self.badgeView.borderColor = .white
        self.badgeView.borderWidth = 2.0
        self.badgeView.contentMode = .scaleAspectFit
        self.badgeView.tintColor = .white
    }
    
    override func layoutSubviews() {
        self.imageView.borderWidth = self.borderWidth
        self.imageView.borderColor = self.borderColor
        
        if (self.avatarURL != self.lastAvatarURL) {
            self.lastAvatarURL = self.avatarURL
            self.imageView.image = nil
            
            if let avatarURL = self.avatarURL {
                self.imageView.af_setImage(withURL: avatarURL)
            }
        }
        
        self.badgeView.isHidden = self.badgeType == .None
        self.badgeView.backgroundColor = self.badgeType.color
        self.badgeView.image = self.badgeType.image?
            .imageWithInsets(insets: self.badgeType.edgeInsets)?
            .withRenderingMode(.alwaysTemplate)
    }
}
