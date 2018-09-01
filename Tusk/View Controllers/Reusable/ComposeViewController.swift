//
//  ComposeViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/28/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import MastodonKit
import YPImagePicker

class ComposeViewController: UIViewController {
    private static let maxCharacterCount: Int = 500
    var remainingCharacters: Int { return ComposeViewController.maxCharacterCount - self.textView.text.count }
    
    @IBOutlet var postButton: UIBarButtonItem!
    @IBOutlet var avatarView: AvatarView!
    @IBOutlet var remainingCharactersLabel: ValidatedLabel!
    @IBOutlet var visibilityIndicator: UIImageView!
    @IBOutlet var textView: TextView!
    
    @IBOutlet var attachmentCollectionView: UICollectionView!
    @IBOutlet var attachmentHeightConstraints: [ToggleLayoutConstraint]!
    
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    private var bottomConstraintMinConstant: CGFloat = 0.0
    
    var mediaAttachments: [(MediaAttachment, YPMediaItem)] = [] {
        didSet {
            if (self.mediaAttachments.count != oldValue.count) {
                self.updateMediaAttachments()
            }
        }
    }
    
    var inReplyTo: Status? = nil
    var visibility: Visibility = .public {
        didSet {
            switch self.visibility {
            case .public: self.visibilityIndicator.image = UIImage(named: "PublicButton")
            case .private: self.visibilityIndicator.image = UIImage(named: "PrivateButton")
            case .direct: self.visibilityIndicator.image = UIImage(named: "MessageButton")
            default: break
            }
        }
    }
    
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
        self.textView.highlightDataMatchers = [
            Regex("@(\\w+)(@\\w+.\\w+)?"),
            Regex("#(\\w+)"),
            Regex("[a-z]*(://)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)")
        ]
        
        if let reply = self.inReplyTo {
            self.textView.text = (
                reply.mentionHandlesForReply(activeAccount: activeAccount).joined(separator: " ") +
                " "
            )
            
            self.textView.updateHighlights()
            self.visibility = reply.visibility
        }
        
        self.updateMediaAttachments()
        self.bottomConstraintMinConstant = self.bottomConstraint.constant
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.textView.becomeFirstResponder()
    }
    
    private func updateMediaAttachments() {
        self.attachmentHeightConstraints.forEach { $0.toggle(on: !self.mediaAttachments.isEmpty) }
        self.attachmentCollectionView.reloadData()
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
    
    @IBAction func attachmentButtonWasTapped(sender: UIButton?) {
        var config = YPImagePickerConfiguration()
        config.library.maxNumberOfItems = 4
        config.library.mediaType = .photoAndVideo

        config.hidesStatusBar = false
        config.onlySquareImagesFromCamera = false
        config.screens = [.library, .photo, .video]
        config.startOnScreen = .library
        
        config.colors.tintColor = sender?.tintColor ?? self.view.tintColor
        UINavigationBar.appearance().tintColor = config.colors.tintColor
        
        let picker = YPImagePicker(configuration: config)
        picker.didFinishPicking(completion: self.pickerDidFinishPicking(picker: picker))
        self.present(picker, animated: true, completion: nil)
    }
    
    @IBAction func mentionButtonWasTapped(sender: UIButton?) {
        self.textView.text = self.textView.text + "@"
    }
    
    @IBAction func hashtagButtonWasTapped(sender: UIButton?) {
        self.textView.text = self.textView.text + "#"
    }
    
    @IBAction func visibilityButtonWasTapped(sender: UIButton?) {
        let handler = { (visibility: Visibility) in { (_: UIAlertAction) in self.visibility = visibility }}
        
        let visibilityPicker = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let publicAction = UIAlertAction(title: "Everyone", style: .default, handler: handler(.public))
        publicAction.setValue(UIImage(named: "PublicButton"), forKey: "image")
        visibilityPicker.addAction(publicAction)
        
        let privateAction = UIAlertAction(title: "Followers", style: .default, handler: handler(.private))
        privateAction.setValue(UIImage(named: "PrivateButton"), forKey: "image")
        visibilityPicker.addAction(privateAction)
        
        let dmAction = UIAlertAction(title: "Direct Message", style: .default, handler: handler(.direct))
        dmAction.setValue(UIImage(named: "MessageButton"), forKey: "image")
        visibilityPicker.addAction(dmAction)
        
        self.present(visibilityPicker, animated: true, completion: nil)
    }
    
    @IBAction func dismiss(sender: UIBarButtonItem? = nil) {
        self.textView.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func post(sender: UIBarButtonItem? = nil) {
        guard let client = GlobalStore.state.auth.client else { return }
        GlobalStore.dispatch(TimelineState.PostStatus(client: client,
                                                      content: self.textView.text,
                                                      inReplyTo: self.inReplyTo,
                                                      visibility: self.visibility))
        self.dismiss(sender: sender)
    }
    
    func pickerDidFinishPicking(picker: YPImagePicker) -> ([YPMediaItem], Bool) -> Void {
        return { [unowned picker] (items: [YPMediaItem], cancelled: Bool) in
            defer { picker.dismiss(animated: true, completion: nil) }
            guard !cancelled else { return }
            
            items.forEach { (item) in
                switch item {
                case .photo(let photo): self.mediaAttachments.append((.png(UIImagePNGRepresentation(photo.image)), item))
                case .video(let video): video.fetchData(completion: { (data) in
                    self.mediaAttachments.append((.other(data, fileExtension: "mov", mimeType: "video/quicktime"), item))
                })
                }
            }
        }
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
        let scrollSize = CGSize(width: textView.frame.width, height: UILayoutFittingExpandedSize.height)
        textView.isScrollEnabled = textView.frame.height < textView.sizeThatFits(scrollSize).height
        self.updateCharacterCount()
    }
}

extension ComposeViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mediaAttachments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ImageAttachmentViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageViewCell",
                                                                               for: indexPath,
                                                                               usingNibNamed: "ImageAttachmentViewCell")
        
        let attachmentInfo = self.mediaAttachments[indexPath.item].1
        switch attachmentInfo {
        case .photo(let photo): cell.imageView.image = photo.image
        case .video(let video): cell.imageView.image = video.thumbnail
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("boop")
        collectionView.deselectItem(at: indexPath, animated: false)
    }
}

class ComposeContainerViewController: UINavigationController {
    var composeViewController: ComposeViewController? {
        return self.viewControllers.first as? ComposeViewController
    }
}
