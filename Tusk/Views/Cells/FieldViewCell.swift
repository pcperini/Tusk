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

// Custom field types
extension FieldViewCell {
    enum CustomFieldCellType: String, CaseIterable {
        case Gender = "(pronoun|gender|sex|⚧|⚥|♂|♀|he.*him|she.*her|they.*them)"
        case Work = "(resume|work|job|cv)"
        case Location = "(location)"
        
        case Instagram = "(ig|insta|gram)"
        case YouTube = "(youtube|yt)"
        case Patreon = "(patreon)"
        case Twitter = "(twitter)"
        case LinkedIn = "(linkedin)"
        case Facebook = "(facebook|fb)"
        case GitHub = "(github|gh)"
        case Twitch = "(twitch)"
        case Dribbble = "(dribbble)"
        case Snapchat = "(snap|snapchat)"
        case Medium = "(medium)"
        
        case Games = "(3ds|switch|friend code|nintendo|xbox)"
        case Support = "(donations|support)"

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
                return matches.count > 0
            }).first ?? .Default
        }
    }
    
    static func iconForCustomField(fieldName: String, fieldValue: String) -> UIImage? {
        let fieldType = CustomFieldCellType(fieldName: fieldName, fieldValue: fieldValue)
        return UIImage(named: "\(fieldType)")
    }
}
