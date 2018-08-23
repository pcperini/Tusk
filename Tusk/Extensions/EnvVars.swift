//
//  EnvVars.swift
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
}
