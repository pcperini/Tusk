//
//  SwiftyRegex.swift
//  SwiftyRegex
//
//  Created by Tomek on 06.03.2016.
//  Copyright © 2016 Tomek Cejner. All rights reserved.
//
import Foundation

public class Regex {
    public typealias Bounds = (min: Int?, max: Int?)
    
    let regularexpression: NSRegularExpression?
    let bounds: Bounds?
    
    public init(_ pattern: String, options: NSRegularExpression.Options = .caseInsensitive, bounds: Bounds? = nil) {
        self.regularexpression = try! NSRegularExpression(pattern: pattern, options: options)
        self.bounds = bounds
    }
    
    public func test(input: String) -> Bool {
        guard let _ = self.matches(input: input, count: 1).first else { return false }
        return true
    }
    
    func rangeOfString(input:String) -> NSRange {
        return NSMakeRange(0, (input.count))
    }
    
    public func matches(input: String, count: Int? = nil) -> [NSTextCheckingResult] {
        if let count = count,
            count == 1,
            let firstMatch = self.regularexpression?.firstMatch(in: input, options: [], range: self.rangeOfString(input: input)) {
            return [firstMatch]
        }
        
        guard let matches = self.regularexpression?.matches(in: input, options: [], range: self.rangeOfString(input: input)),
            !matches.isEmpty else { return [] }
        
        let filteredMatches = matches.filter({
            ($0.range.length >= self.bounds?.min ?? Int.min) && ($0.range.length <= self.bounds?.max ?? Int.max)
        })
        
        let count = max(min(count ?? filteredMatches.count, filteredMatches.count), 0)
        return Array(filteredMatches[0 ..< count])
    }
}

extension String {
    subscript(range: NSRange) -> String? {
        get {
            guard let range = Range(range, in: self) else { return nil }
            return String(self[range])
        }
    }
}
