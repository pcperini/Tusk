//
//  AuthViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 9/12/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

// TODO: Incorporate selection wizard using: https://instances.social/api/doc/

import UIKit
import DeckTransition

class AuthViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    private var bottomConstraintMinConstant: CGFloat = 0.0
    
    private var globalParent: UIViewController? = nil
    
    static let PresentationSegueName: String = "PresentAuthViewController"
    
    static func displayIfNeeded(fromViewController parent: UIViewController, sender: Any?) {
        guard parent.childViewControllers.first(where: { $0 is AuthViewController }) == nil else { return }
        parent.performSegue(withIdentifier: AuthViewController.PresentationSegueName, sender: sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        self.modalPresentationCapturesStatusBarAppearance = true
        self.bottomConstraintMinConstant = self.bottomConstraint.constant
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.globalParent = self.presentingViewController
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
    
    override func viewDidDisappear(_ animated: Bool) {
        guard let parent = self.globalParent else { return }
        AuthViewController.displayIfNeeded(fromViewController: parent, sender: nil)
        
        super.viewDidDisappear(animated)
    }
    
    @objc func keyboardWillMove(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
            let endFrameValue = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber else { return }
        
        UIView.animate(withDuration: duration.doubleValue) {
            switch notification.name {
            case .UIKeyboardWillShow: do {
                self.bottomConstraint.constant = self.bottomConstraintMinConstant - endFrameValue.height
                }
            case .UIKeyboardWillHide: do {
                self.bottomConstraint.constant = self.bottomConstraintMinConstant
                }
            default: break
            }
            
            self.view.layoutIfNeeded()
        }
    }
}

extension AuthViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let instance = textField.text, !instance.isEmpty else { return false }
        
        
        return true
    }
}
