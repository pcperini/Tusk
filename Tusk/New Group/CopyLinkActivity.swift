//
//  CopyLinkActivity.swift
//  Tusk
//
//  Created by Patrick Perini on 9/3/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

class CopyLinkActivity: UIActivity {
    private var url: URL? = nil
    
    override class var activityCategory: UIActivityCategory {
        return .action
    }
    
    override var activityType: UIActivityType? {
        guard let bundleId = Bundle.main.bundleIdentifier else {return nil}
        return UIActivityType(rawValue: bundleId + "\(self.classForCoder)")
    }
    
    override var activityTitle: String? {
        return "Copy Link"
    }
    
    override var activityImage: UIImage? {
        return UIImage(named: "LinkButton")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return !activityItems.compactMap({ (item: Any) -> URL? in
            if let item = item as? URL { return item }
            guard let str = item as? String else { return nil }
            return URL(string: str)
        }).isEmpty
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        self.url = activityItems.compactMap({ (item: Any) -> URL? in
            if let item = item as? URL { return item }
            guard let str = item as? String else { return nil }
            return URL(string: str)
        }).first
    }
    
    override func perform() {
        var success = false
        defer { self.activityDidFinish(success) }
        
        guard let str = self.url?.absoluteString else { return }
        UIPasteboard.general.string = str
        success = true
    }
}
