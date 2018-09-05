//
//  Bundle+Info.swift
//  Tusk
//
//  Created by Patrick Perini on 8/23/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation

extension Bundle {
    var envVars: [String: Any] {
        return self.infoDictionary!["TuskEnvVars"] as! [String: Any]
    }
    
    var developers: [String] {
        return self.envVars["TuskDevelopers"] as! [String]
    }
    
    struct LogCredentials { let id: String; let secret: String; let encryption: String }
    var logCredentials: LogCredentials {
        let credentials = self.envVars["SBLogCredentials"] as! [String: String]
        return LogCredentials(id: credentials["ID"]!,
                              secret: credentials["Secret"]!,
                              encryption: credentials["Encryption"]!)
    }
}

extension Bundle {
    var version: String {
        return self.infoDictionary!["CFBundleShortVersionString"] as! String
    }
    var build: String {
        return self.infoDictionary!["CFBundleVersion"] as! String
    }
}
