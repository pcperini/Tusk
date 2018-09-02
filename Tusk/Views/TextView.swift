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
    @IBInspectable var sizesToFitContent: Bool = true
    @IBInspectable var maxLinkLength: Int = 30
    
    var linkLineBreakMode: NSLineBreakMode = .byTruncatingTail
    var hideLinkCriteria: (String) -> Bool = { (_) in false }
    
    var emojis: [(String, URL)] = []
    var emojiSize: CGSize {
        return CGSize(width: (self.font?.pointSize ?? UIFont.systemFontSize) * 1.5,
                      height: (self.font?.pointSize ?? UIFont.systemFontSize) * 1.5)
    }
    
    var highlightDataMatchers: [Regex] = []
    private var preHighlightTextColor: UIColor!
    
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
            self.text = ""
            guard let text = self.htmlText else { return }
            guard text.contains("<") else { self.text = text; return }
            
            let originalFont = self.font
            let options: [String: NSObject] = [
                DTUseiOS6Attributes: NSNumber(booleanLiteral: true),
                DTDefaultFontName: NSString(string: self.font!.fontName),
                DTDefaultFontSize: NSNumber(value: Float(self.font!.pointSize)),
                DTDefaultLinkColor: self.preHighlightTextColor,
                DTDefaultLinkDecoration: NSNumber(booleanLiteral: false),
                DTDefaultTextColor: self.preHighlightTextColor,
                DTDefaultTextAlignment: NSNumber(value: self.coreTextAlignment.rawValue),
                DTDocumentPreserveTrailingSpaces: NSNumber(booleanLiteral: false)
            ]

            let builder = DTHTMLAttributedStringBuilder(html: text.data(using: .utf8),
                                                        options: options,
                                                        documentAttributes: nil)
            let linkRegex = Regex("([a-z]+:\\/\\/.{\(self.maxLinkLength),})\\s?")
            
            var attributedText = builder?.generatedAttributedString()
                .attributedStringByTrimmingCharacterSet(charSet: .whitespacesAndNewlines)
                .replacingMatches(to: linkRegex, with: { (match) -> String in
                    if (self.hideLinkCriteria(match)) { return "" }
                    switch self.linkLineBreakMode {
                    case .byCharWrapping, .byWordWrapping: return match
                    case .byClipping: return "\(match.prefix(self.maxLinkLength))) "
                    case .byTruncatingHead: return "...\(match.suffix(self.maxLinkLength - 3)) "
                    case .byTruncatingMiddle: return "\(match.prefix((self.maxLinkLength / 2) - 3))...\(match.suffix(self.maxLinkLength / 2)) "
                    case .byTruncatingTail: return "\(match.prefix(self.maxLinkLength - 3))... "
                    }
                })
                .attributedStringByTrimmingCharacterSet(charSet: .whitespacesAndNewlines)
            
            attributedText = self.emojis.reduce(attributedText, { (all, emoji) in
                let attachment = NSTextAttachment()
                attachment.image = try? UIImage(contentsOf: emoji.1, cachePolicy: .returnCacheDataElseLoad)
                    .af_imageAspectScaled(toFill: self.emojiSize)
                
                return all?.replacingOccurrences(of: ":\(emoji.0):",
                                                 with: NSAttributedString(attachment: attachment),
                                                 options: .literal,
                                                 range: NSRange(location: 0, length: all?.length ?? 0))
            })
            
            self.attributedText = attributedText
            self.font = originalFont
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.preHighlightTextColor = self.textColor ?? .black
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textViewDidChange(notification:)),
                                               name: .UITextViewTextDidChange,
                                               object: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.textContainerInset = .zero
        self.textContainer.lineFragmentPadding = 0
        self.contentInset = .zero
        
        if self.sizesToFitContent {
            let minimumHeight = self.sizeThatFits(CGSize(width: self.bounds.size.width,
                                                         height: CGFloat.greatestFiniteMagnitude)).height
            self.bounds = CGRect(origin: .zero, size: CGSize(width: self.bounds.width, height: minimumHeight))
        }
    }
    
    func updateHighlights() {
        guard !self.highlightDataMatchers.isEmpty else { return }
        guard let mutableText = self.attributedText.mutableCopy() as? NSMutableAttributedString else { return }
        
        mutableText.addAttribute(.foregroundColor, value: self.preHighlightTextColor as Any, range: NSRange(location: 0, length: mutableText.length))
        self.highlightDataMatchers.forEach { (regex) in
            regex.matches(input: mutableText.string).forEach({ (match: NSTextCheckingResult) in
                mutableText.addAttribute(.foregroundColor, value: self.tintColor, range: match.range)
            })
        }
        
        self.attributedText = mutableText
    }
    
    @objc func textViewDidChange(notification: Notification) {
        guard let view = notification.object as? TextView, view == self else { return }
        self.updateHighlights()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if (self.isEditable) {
            return super.hitTest(point, with: event)
        }
        
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
        if (self.isEditable) {
            return super.touchesBegan(touches, with: event)
        }
        
        // location of the tap
        var location = touches.first!.location(in: self)
        location.x -= self.textContainerInset.left
        location.y -= self.textContainerInset.top
        
        // find the character that's been tapped
        let characterIndex = self.layoutManager.characterIndex(for: location, in: self.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        var range = NSRange()
        let attributes = self.attributedText.attributes(at: characterIndex, effectiveRange: &range)
        
        if let link = attributes[.link] as? URL {
            let _ = self.delegate?.textView?(self, shouldInteractWith: link, in: range, interaction: .invokeDefaultAction)
        }
    }
}
