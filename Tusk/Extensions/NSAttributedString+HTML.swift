//
//  NSAttributedString+HTML.swift
//  Tusk
//
//  Created by Patrick Perini on 8/15/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import DTCoreText

protocol TextReplaceable {}
extension String: TextReplaceable {}
extension NSAttributedString: TextReplaceable {}

extension NSAttributedString {
    var allAttributes: [NSAttributedStringKey: Any] {
        return self.attributes(at: 0, longestEffectiveRange: nil, in: NSRange(location: 0, length: self.length))
    }
    
    public func attributedStringByTrimmingCharacterSet(charSet: CharacterSet) -> NSAttributedString {
        let modifiedString = NSMutableAttributedString(attributedString: self)
        modifiedString.trimCharactersInSet(charSet: charSet)
        return NSAttributedString(attributedString: modifiedString)
    }
    
    convenience init?(htmlString: String,
                      font: UIFont? = nil,
                      baseTextColor: UIColor = .darkText,
                      alignment: CTTextAlignment = .left,
                      linkMaxLength: Int = 10000,
                      linkHideCriteria: ((String) -> Bool)? = nil,
                      linkLineBreakMode: NSLineBreakMode = .byClipping) {
        guard !htmlString.isEmpty else { self.init(); return }
        guard htmlString.contains("<") else { self.init(string: htmlString); return }
        
        var options: [String: NSObject] = [
            DTUseiOS6Attributes: NSNumber(booleanLiteral: true),
            DTDefaultLinkColor: baseTextColor,
            DTDefaultLinkDecoration: NSNumber(booleanLiteral: false),
            DTDefaultTextColor: baseTextColor,
            DTDefaultTextAlignment: NSNumber(value: alignment.rawValue),
            DTDocumentPreserveTrailingSpaces: NSNumber(booleanLiteral: false)
        ]
        
        if let font = font {
            options[DTDefaultFontSize] = NSNumber(value: Float(font.pointSize))
            options[DTDefaultFontName] = NSString(string: font.fontName)
        }
        
        let builder = DTHTMLAttributedStringBuilder(html: htmlString.data(using: .utf8),
                                                    options: options,
                                                    documentAttributes: nil)
        let linkRegex = Regex("(([a-z]+:\\/\\/)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&\\/\\/=]*))")
        
        guard let attributedString = builder?.generatedAttributedString()
            .attributedStringByTrimmingCharacterSet(charSet: .whitespacesAndNewlines)
            .replacingMatches(to: linkRegex, with: { (match) -> String in
                if (linkHideCriteria?(match) ?? false) { return "" }
                if (match.lengthOfBytes(using: .utf8) < linkMaxLength) { return match }
                
                switch linkLineBreakMode {
                case .byCharWrapping, .byWordWrapping: return match
                case .byClipping: return "\(match.prefix(linkMaxLength))) "
                case .byTruncatingHead: return "...\(match.suffix(linkMaxLength - 3))"
                case .byTruncatingMiddle: return "\(match.prefix((linkMaxLength / 2) - 3))...\(match.suffix(linkMaxLength / 2))"
                case .byTruncatingTail: return "\(match.prefix(linkMaxLength - 3))..."
                }
            })
            .attributedStringByTrimmingCharacterSet(charSet: .whitespacesAndNewlines) else { return nil }
        self.init(attributedString: attributedString)
    }
    
    func replacingRange(range: NSRange, with: TextReplaceable) -> NSAttributedString {
        guard let replacement = self.mutableCopy() as? NSMutableAttributedString else { return self }
        replacement.replaceRange(range: range, with: with)
        return replacement
    }
    
    func replacingOccurrences(of: String, with: TextReplaceable, options: NSString.CompareOptions, range: NSRange) -> NSAttributedString {
        guard let mutable = self.mutableCopy() as? NSMutableAttributedString else { return self }
        
        var searchRange = NSRange(location: 0, length: mutable.length)
        var foundRange: NSRange
        
        while (searchRange.location < mutable.length) {
            searchRange.length = mutable.length - searchRange.location
            foundRange = mutable.mutableString.range(of: of, options: options, range: searchRange)
            guard foundRange.location != NSNotFound else { break }
            
            mutable.replaceRange(range: foundRange,
                                 with: with)
        }

        return mutable
    }
    
    func replacingMatches(to regex: Regex, with: (String) -> TextReplaceable) -> NSAttributedString {
        guard let match = regex.matches(input: self.string).first, let substring = self.string[match.range] else { return self }
        let replaced = self.replacingRange(range: match.range, with: with(substring))
        guard replaced != self else { return self }
        return replaced.replacingMatches(to: regex, with: with)
    }
}

extension NSMutableAttributedString {
    public func trimCharactersInSet(charSet: CharacterSet) {
        var range = (string as NSString).rangeOfCharacter(from: charSet)
        
        // Trim leading characters from character set.
        while range.length != 0 && range.location == 0 {
            replaceCharacters(in: range, with: "")
            range = (string as NSString).rangeOfCharacter(from: charSet)
        }
        
        // Trim trailing characters from character set.
        range = (string as NSString).rangeOfCharacter(from: charSet, options: .backwards)
        while range.length != 0 && NSMaxRange(range) == length {
            replaceCharacters(in: range, with: "")
            range = (string as NSString).rangeOfCharacter(from: charSet, options: .backwards)
        }
    }
    
    func replaceRange(range: NSRange, with: TextReplaceable) {
        let attributes = self.attributes(at: range.location,
                                         longestEffectiveRange: nil,
                                         in: NSRange(location: 0, length: range.length))
        
        let replacement: NSAttributedString
        switch with {
        case let with as String: do {
            let mut = NSMutableAttributedString(string: with)
            mut.setAttributes(attributes, range: NSRange(location: 0, length: mut.length))
            replacement = mut
            }
        case let with as NSAttributedString: replacement = with
        default: replacement = NSAttributedString()
        }
        
        self.replaceCharacters(in: range, with: replacement)
    }
}

extension String {
    init?(htmlString: String) {
        guard let attributedString = NSAttributedString(htmlString: htmlString) else { return nil }
        self.init(attributedString.string)
    }
}
