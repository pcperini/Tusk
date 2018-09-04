//
//  Clonable.swift
//  Tusk
//
//  Created by Patrick Perini on 9/4/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation

struct CloneError: Error { let description: String }

protocol Clonable: Encodable, Decodable {
    var jsonValue: [String: Any]? { get }
    func cloned(changes: [String: Any]) throws -> Self
}

extension Clonable {
    var jsonValue: [String: Any]? {
        guard let jsonValue = try? JSONEncoder().encode(self),
            let jsonAttempt = try? JSONSerialization.jsonObject(with: jsonValue,options: .mutableContainers) else { return nil }
        return jsonAttempt as? [String: Any]
    }
    
    func cloned(changes: [String: Any] = [:]) throws -> Self {
        guard var mutableJSONValue = self.jsonValue else {
            throw CloneError(description: "Could not serialize \(self)")
        }
        
        let changes: [String: Any] = try changes.reduce([:]) { (all, next) in
            var all = all
            if let clonableNext = next.value as? Clonable {
                all[next.key] = try clonableNext.cloned()
            } else {
                all[next.key] = next.value
            }
            
            return all
        }
        
        changes.forEach { (change) in mutableJSONValue[change.key] = change.value }
        let jsonData = try JSONSerialization.data(withJSONObject: mutableJSONValue, options: .init(rawValue: 0))
        
        return try JSONDecoder().decode(Self.self, from: jsonData)
    }
}
