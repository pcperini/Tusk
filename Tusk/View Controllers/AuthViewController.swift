//
//  AuthViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 9/12/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

// TODO: Incorporate selection wizard using: https://instances.social/api/doc/

import UIKit
import ReSwift
import SafariServices

class AuthViewController: UIViewController, SubscriptionResponder {
    typealias StoreSubscriberStateType = AuthState
    
    private static var state: AuthState { return GlobalStore.state.auth }
    lazy var subscriber: Subscriber = Subscriber(state: { $0.auth }, newState: self.newState)
    
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    private var bottomConstraintMinConstant: CGFloat = 0.0
    
    private var oldPresentingViewController: UIViewController? = nil
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
        
    static func displayIfNeeded(fromViewController presenting: UIViewController, usingSegueNamed segueName: String, sender: Any?) {
        let shouldPresent = (
            self.state.instance == nil ||
            self.state.accessToken == nil
        )
        
        guard shouldPresent, !(presenting.presentedViewController is AuthViewController) else { return }
        presenting.performSegue(withIdentifier: segueName, sender: sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        self.modalPresentationCapturesStatusBarAppearance = true
        self.bottomConstraintMinConstant = self.bottomConstraint.constant
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.oldPresentingViewController = self.presentingViewController
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillMove(notification:)),
                                               name: .UIKeyboardWillShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillMove(notification:)),
                                               name: .UIKeyboardWillHide,
                                               object: nil)
        
        self.subscriber.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.oldPresentingViewController?.viewDidAppear(true)
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
    
    func newState(state: AuthState) {
        if (state.instance == nil) {
            return
        } else if (state.code == nil &&
            state.accessToken == nil &&
            state.oauthURL != nil) {
            let safariVC = SFSafariViewController(url: state.oauthURL!)
            safariVC.delegate = self
            self.present(safariVC, animated: true, completion: nil)
            
        } else if (state.accessToken != nil) {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension AuthViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let instance = textField.text, !instance.isEmpty else { return false }
        GlobalStore.dispatch(AuthState.CreateAppForInstance(value: instance))
        return true
    }
}
