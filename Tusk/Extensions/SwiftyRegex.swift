//
//  SwiftyRegex.swift
//  SwiftyRegex
//
//  Created by Tomek on 06.03.2016.
//  Copyright © 2016 Tomek Cejner. All rights reserved.
//
import Foundation

public class Regex {
    let regularexpression: NSRegularExpression?
    
    public init(_ pattern: String, options: NSRegularExpression.Options = .caseInsensitive) {
        self.regularexpression = try! NSRegularExpression(pattern: pattern, options: options)
    }
    
    public func test(input: String) -> Bool {
        if let matchCount = self.regularexpression?.numberOfMatches(in: input, options: [], range: rangeOfString(input: input)) {
            return matchCount > 0
        } else {
            return false
        }
    }
    
    func rangeOfString(input:String) -> NSRange {
        return NSMakeRange(0, (input.count))
    }
    
    public func matches(input: String) -> [NSTextCheckingResult] {
        return self.regularexpression?.matches(in: input, options: [], range:rangeOfString(input: input)) ?? []
    }
    
    public func captures(input: String) -> [String] {
        if let match = self.regularexpression?.firstMatch(in: input, options: [], range: rangeOfString(input: input)) {
            var i = 0
            var ret:[String] = []
            while (i < match.numberOfRanges) {
                ret.append((input as NSString).substring(with: match.range(at: i)))
                i += 1
            }
            return ret
        } else {
            return []
        }
        
    }
}

infix operator =~
public func =~ (input: String, pattern: String) -> Bool {
    return Regex(pattern).test(input: input)
}

extension String {
    subscript(range: NSRange) -> String? {
        get {
            guard let range = Range(range, in: self) else { return nil }
            return String(self[range])
        }
    }
}
