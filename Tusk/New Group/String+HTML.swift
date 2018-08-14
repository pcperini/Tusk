//
//  String+HTML.swift
//  Tusk
//
//  Created by Patrick Perini on 8/12/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import UIKit

extension String{
    func attributedHTMLString() -> NSAttributedString{
        guard let data = data(using: .utf16) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data,
                                          options: [
                                            .documentType: NSAttributedString.DocumentType.html,
                                            .defaultAttributes: String.Encoding.utf16.rawValue
                                          ],
                                          documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
}
