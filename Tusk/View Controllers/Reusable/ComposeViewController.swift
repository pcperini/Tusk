//
//  ComposeViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/28/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit

class ComposeViewController: UIViewController {
    private static let maxCharacterCount: Int = 500
    var remainingCharacters: Int { return ComposeViewController.maxCharacterCount - self.textView.text.count }
    
    @IBOutlet var postButton: UIBarButtonItem!
    @IBOutlet var avatarView: AvatarView!
    @IBOutlet var remainingCharactersLabel: ValidatedLabel!
    @IBOutlet var textView: UITextView!
    
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    
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
        
        guard let activeUser = GlobalStore.state.accounts.activeAccount?.account else { self.dismiss(); return }
        self.avatarView.avatarURL = URL(string: activeUser.avatar)!
        self.avatarView.badgeType = AvatarView.BadgeType(account: activeUser)
        
        self.updateCharacterCount()
        
        self.textView.text = ""
        self.textView.becomeFirstResponder()
    }
    
    @objc func keyboardWillMove(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let endFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue,
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber else { return }
        let height = endFrame.cgRectValue.height
        
        self.textView.isScrollEnabled = height < self.textView.contentSize.height
        UIView.animate(withDuration: duration.doubleValue) {
            switch notification.name {
            case .UIKeyboardWillShow: self.bottomConstraint.constant += height
            case .UIKeyboardWillHide: self.bottomConstraint.constant -= height
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
        GlobalStore.dispatch(TimelineState.PostStatus(client: client, content: self.textView.text))
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
        textView.isScrollEnabled = (textView.frame.minY + self.bottomConstraint.constant) < textView.sizeThatFits(textView.frame.size).height
        self.updateCharacterCount()
    }
}
