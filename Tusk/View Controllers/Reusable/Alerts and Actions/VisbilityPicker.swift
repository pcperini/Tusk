//
//  VisbilityPicker.swift
//  Tusk
//
//  Created by Patrick Perini on 9/16/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit

class VisibilityPicker: UIAlertController {
    convenience init(handler: @escaping (Visibility) -> Void) {
        let responder = { (visibility: Visibility) in { (_: UIAlertAction) in handler(visibility) } }
        self.init(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let publicAction = UIAlertAction(title: "Everyone", style: .default, handler: responder(.public))
        publicAction.setValue(UIImage(named: "PublicButton"), forKey: "image")
        self.addAction(publicAction)
        
        let privateAction = UIAlertAction(title: "Followers", style: .default, handler: responder(.private))
        privateAction.setValue(UIImage(named: "PrivateButton"), forKey: "image")
        self.addAction(privateAction)
        
        let dmAction = UIAlertAction(title: "Direct Message", style: .default, handler: responder(.direct))
        dmAction.setValue(UIImage(named: "MessageButton"), forKey: "image")
        self.addAction(dmAction)
    }
}


