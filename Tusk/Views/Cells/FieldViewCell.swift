//
//  FieldCellView.swift
//  Tusk
//
//  Created by Patrick Perini on 8/14/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

class FieldViewCell: TableViewCell {
    @IBOutlet var iconView: UIImageView!
    @IBOutlet var fieldNameLabel: UILabel!
    @IBOutlet var fieldValueTextView: TextView!
    
    var url: URL?
    
    static func iconForStat(stat: AccountViewController.Stat) -> UIImage? {
        switch stat {
        case .Statuses: return UIImage(named: "StatusesField")
        case .Followers: return UIImage(named: "FollowersField")
        case .Follows: return UIImage(named: "FollowsField")
        }
    }
}

// Custom field types
extension FieldViewCell {
    enum CustomFieldCellType: String, CaseIterable {
        case Gender = "(pronoun|gender|sex|⚧|⚥|♂|♀|he.*him|she.*her|they.*them)"
        case Work = "(resume|work|job|cv)"
        case Location = "(location|🏠|🏡)"
        
        case Instagram = "(\\big\\b|\\binsta\\b|instagram|\\bgram\\b)"
        case YouTube = "(youtube|\\byt\\b)"
        case Patreon = "(patreon)"
        case Twitter = "(twitter)"
        case LinkedIn = "(linkedin)"
        case Facebook = "(facebook|\\bfb\\b)"
        case GitHub = "(github|\\bgh\\b)"
        case Twitch = "(twitch)"
        case Dribbble = "(dribbble)"
        case Snapchat = "(\\bsnap\\b|snapchat)"
        case Medium = "(medium)"
        case Tumblr = "(tumblr)"
        
        case Games = "(3ds|switch|friend code|nintendo|xbox|psn)"
        case Support = "(donations|support|cash|pay|venmo)"

        case Website = "(web|site|page|www|http(s)?:\\/\\/)"
        case Email = "(contact|e?mail|.+@.+\\.)"
        case Blog = "(blog)"
        
        case Default = "(.*)"
        
        init(fieldName: String, fieldValue: String) {
            let (lhs, rhs) = (CustomFieldCellType(rawValue: fieldName), CustomFieldCellType(rawValue: fieldValue))
            if lhs != .Default { self = lhs }
            else if rhs != .Default { self = rhs }
            else { self = .Default }
        }
        
        init(rawValue: String) {
            self = CustomFieldCellType.allCases.filter({ (cellType) in
                let regex = try! NSRegularExpression(pattern: cellType.rawValue, options: [.caseInsensitive])
                let matches = regex.matches(in: rawValue.folding(options: .diacriticInsensitive, locale: .current),
                                            range: NSRange(rawValue.startIndex..., in: rawValue))
                return !matches.isEmpty
            }).first ?? .Default
        }
    }
    
    static func iconForCustomField(fieldName: String, fieldValue: String) -> UIImage? {
        let fieldType = CustomFieldCellType(fieldName: fieldName, fieldValue: fieldValue)
        return UIImage(named: "\(fieldType)Field")
    }
}
