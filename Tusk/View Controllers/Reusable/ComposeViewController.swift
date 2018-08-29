//
//  ComposeViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/28/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit

class ComposeViewController: UIViewController {
    private static let maxCharacterCount: Int = 500
    var remainingCharacters: Int { return ComposeViewController.maxCharacterCount - self.textView.text.count }
    
    @IBOutlet var postButton: UIBarButtonItem!
    @IBOutlet var avatarView: AvatarView!
    @IBOutlet var remainingCharactersLabel: ValidatedLabel!
    @IBOutlet var textView: UITextView!
    
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    
    var inReplyTo: Status? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillMove(notification:)),
                                               name: .UIKeyboardWillShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillMove(notification:)),
                                               name: .UIKeyboardWillHide,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let activeAccount = GlobalStore.state.accounts.activeAccount?.account else { self.dismiss(); return }
        self.avatarView.avatarURL = URL(string: activeAccount.avatar)!
        self.avatarView.badgeType = AvatarView.BadgeType(account: activeAccount)
        
        self.updateCharacterCount()
        
        self.textView.text = ""
        self.textView.becomeFirstResponder()
        
        if let reply = self.inReplyTo {
            self.textView.text = (
                reply.mentionHandlesForReply(activeAccount: activeAccount).joined(separator: " ") +
                " "
            )
        }
    }
    
    @objc func keyboardWillMove(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let endFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue,
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber else { return }
        let height = endFrame.cgRectValue.height
        
        UIView.animate(withDuration: duration.doubleValue) {
            switch notification.name {
            case .UIKeyboardWillShow: self.bottomConstraint.constant -= height
            case .UIKeyboardWillHide: self.bottomConstraint.constant += height
            default: break
            }
        }
    }
    
    @IBAction func dismiss(sender: UIBarButtonItem? = nil) {
        self.textView.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func post(sender: UIBarButtonItem? = nil) {
        guard let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(TimelineState.PostStatus(client: client, content: self.textView.text, inReplyTo: self.inReplyTo))
        self.dismiss(sender: sender)
    }
    
    func updateCharacterCount() {
        self.remainingCharactersLabel.text = "\(self.remainingCharacters)"
        
        let minimumValidCharacters = ComposeViewController.maxCharacterCount / 5
        self.postButton.isEnabled = true
        
        switch self.remainingCharacters {
        case 0...minimumValidCharacters: self.remainingCharactersLabel.validity = .Warn
        case ...0: do {
            self.remainingCharactersLabel.validity = .Invalid
            self.postButton.isEnabled = false
            }
        default: self.remainingCharactersLabel.validity = .Valid
        }
    }
}

extension ComposeViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textView.isScrollEnabled = textView.frame.height < textView.sizeThatFits(textView.frame.size).height
        self.updateCharacterCount()
    }
}

class ComposeContainerViewController: UINavigationController {
    var composeViewController: ComposeViewController? {
        return self.viewControllers.first as? ComposeViewController
    }
}
