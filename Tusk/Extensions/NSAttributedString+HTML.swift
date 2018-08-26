//
//  NSAttributedString+HTML.swift
//  Tusk
//
//  Created by Patrick Perini on 8/15/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import DTCoreText

extension NSAttributedString {
    var allAttributes: [NSAttributedStringKey: Any] {
        return self.attributes(at: 0, longestEffectiveRange: nil, in: NSRange(location: 0, length: self.length))
    }
    
    public func attributedStringByTrimmingCharacterSet(charSet: CharacterSet) -> NSAttributedString {
        let modifiedString = NSMutableAttributedString(attributedString: self)
        modifiedString.trimCharactersInSet(charSet: charSet)
        return NSAttributedString(attributedString: modifiedString)
    }
    
    convenience init?(htmlString: String) {
        let stringBuilder = DTHTMLAttributedStringBuilder(html: htmlString.data(using: .utf8),
                                                          options: [DTUseiOS6Attributes: NSNumber(booleanLiteral: true)],
                                                          documentAttributes: nil)
        guard let builder = stringBuilder else { return nil }
        guard let attributedString = builder.generatedAttributedString()?.attributedStringByTrimmingCharacterSet(charSet: .whitespacesAndNewlines) else { return nil }
        self.init(attributedString: attributedString)
    }
    
    public func replacingOccurrences(of: String, with: String, options: NSString.CompareOptions, range: NSRange) -> NSAttributedString {
        guard let mutable = self.mutableCopy() as? NSMutableAttributedString else { return self }
        mutable.mutableString.replaceOccurrences(of: of, with: with, options: options, range: range)
        return mutable
    }
    
    public func replacingMatches(to regex: Regex, with: (String) -> String) -> NSAttributedString {
        return regex.captures(input: self.string).reduce(self) { (latest, nextCapture) in
            latest.replacingOccurrences(of: nextCapture,
                                        with: with(nextCapture),
                                        options: .regularExpression,
                                        range: regex.rangeOfString(input: latest.string))
        }
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
}
