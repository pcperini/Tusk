//
//  TextView.swift
//  Tusk
//
//  Created by Patrick Perini on 8/13/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import DTCoreText

@IBDesignable class TextView: UITextView {    
    private var coreTextAlignment: CTTextAlignment {
        switch self.textAlignment {
        case .left: return .left
        case .center: return .center
        case .right: return .right
        case .justified: return .justified
        case .natural: return .natural
        }
    }
    
    var htmlText: String? {
        didSet {
            guard let text = self.htmlText else { return }
            guard text.contains("<") else { self.text = text; return }
            
            let options: [String: NSObject] = [
                DTUseiOS6Attributes: NSNumber(booleanLiteral: true),
                DTDefaultFontName: NSString(string: self.font!.fontName),
                DTDefaultFontSize: NSNumber(value: Float(self.font!.pointSize)),
                DTDefaultLinkColor: self.textColor ?? .black,
                DTDefaultLinkDecoration: NSNumber(booleanLiteral: false),
                DTDefaultTextColor: self.textColor ?? .black,
                DTDefaultTextAlignment: NSNumber(value: self.coreTextAlignment.rawValue),
                DTDocumentPreserveTrailingSpaces: NSNumber(booleanLiteral: false)
            ]

            let builder = DTHTMLAttributedStringBuilder(html: text.data(using: .utf8),
                                                        options: options,
                                                        documentAttributes: nil)
            self.attributedText = builder?.generatedAttributedString()
                .attributedStringByTrimmingCharacterSet(charSet: .whitespacesAndNewlines)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.textContainerInset = .zero
        self.textContainer.lineFragmentPadding = 0
        self.contentInset = .zero
        
        let minimumHeight = self.sizeThatFits(CGSize(width: self.bounds.size.width,
                                                     height: CGFloat.greatestFiniteMagnitude)).height
        self.bounds = CGRect(origin: .zero, size: CGSize(width: self.bounds.width, height: minimumHeight))
    }
    
    override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        super.setContentOffset(contentOffset, animated: false)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let attributedText = self.attributedText, attributedText.length > 0 else { return nil }
        
        // location of the tap
        var location = point
        location.x -= self.textContainerInset.left
        location.y -= self.textContainerInset.top
        
        // find the character that's been tapped
        let characterIndex = self.layoutManager.characterIndex(for: location, in: self.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        let attributes = attributedText.attributes(at: characterIndex, effectiveRange: nil)
        
        if attributes[.link] != nil {
            return super.hitTest(point, with: event)
        }
        
        return nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // location of the tap
        var location = touches.first!.location(in: self)
        location.x -= self.textContainerInset.left
        location.y -= self.textContainerInset.top
        
        // find the character that's been tapped
        let characterIndex = self.layoutManager.characterIndex(for: location, in: self.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        let attributes = self.attributedText.attributes(at: characterIndex, effectiveRange: nil)
        
        if let link = attributes[.link] as? URL {
            let _ = self.delegate?.textView?(self, shouldInteractWith: link, in: NSRange(), interaction: .invokeDefaultAction)
        }
    }
}
