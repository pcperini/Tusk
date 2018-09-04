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
    
    convenience init?(htmlString: String) {
        guard !htmlString.isEmpty else { self.init(); return }
        let stringBuilder = DTHTMLAttributedStringBuilder(html: htmlString.data(using: .utf8),
                                                          options: [DTUseiOS6Attributes: NSNumber(booleanLiteral: true)],
                                                          documentAttributes: nil)
        guard let builder = stringBuilder else { return nil }
        guard let attributedString = builder.generatedAttributedString()?.attributedStringByTrimmingCharacterSet(charSet: .whitespacesAndNewlines) else { return nil }
        self.init(attributedString: attributedString)
    }
    
    func replacingOccurrences(of: String, with: TextReplaceable, options: NSString.CompareOptions, range: NSRange) -> NSAttributedString {
        guard let mutable = self.mutableCopy() as? NSMutableAttributedString else { return self }
        
        var searchRange = NSRange(location: 0, length: mutable.length)
        var foundRange: NSRange
        
        while (searchRange.location < mutable.length) {
            searchRange.length = mutable.length - searchRange.location
            foundRange = mutable.mutableString.range(of: of, options: [], range: searchRange)
            guard foundRange.location != NSNotFound else { break }
            
            let attributes = mutable.attributes(at: foundRange.location,
                                                longestEffectiveRange: nil,
                                                in: NSRange(location: 0, length: foundRange.length))

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

            mutable.replaceCharacters(in: foundRange, with: replacement)
        }

        return mutable
    }
    
    func replacingMatches(to regex: Regex, with: (String) -> TextReplaceable) -> NSAttributedString {
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

//extension NSString {
//    func ranges(of: String, range: NSRange? = nil, results: [NSRange] = []) -> [NSRange] {
//        let range = range ?? NSRange(location: 0, length: self.length)
//        if (range.location + range.length > self.length) {
//            return results
//        }
//
//        let nextString = self.substring(with: range)
//        print("searching for \(of) in \(nextString), \(range)")
//        var match = NSString(string: nextString).range(of: of)
//        if (match.location == NSNotFound) {
//            return results
//        }
//
//        let nextStart = match.location + match.length
//        if let lastMatch = results.last {
//            match.location += lastMatch.location + lastMatch.length
//        }
//
//        print("found in \(match). starting in \(nextStart)")
//        return nextString.ranges(of: of,
//                                 range: NSRange(location: nextStart,
//                                                length: self.length - nextStart),
//                                 results: results + [match])
//    }
//}
