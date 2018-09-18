//
//  SettingsViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 9/5/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import SafariServices
import YPImagePicker
import MastodonKit

class SettingsViewController: UITableViewController {
    static let bugURL: URL = URL(string: "https://github.com/pcperini/Tusk---Issues/issues")!
    
    var accountState: AccountState? { return GlobalStore.state.accounts.activeAccount }
    var defaultsState: StoredDefaultsState { return GlobalStore.state.storedDefaults }
    var subscriber: Subscriber!
    
    @IBOutlet var displayNameField: UITextField!
    @IBOutlet var avatarView: UIImageView!
    @IBOutlet var headerView: UIImageView!
    @IBOutlet var isBotToggle: UISwitch!
    @IBOutlet var isLockedToggle: UISwitch!
    
    @IBOutlet var metaLabelFields: [UITextField]!
    @IBOutlet var metaValueFields: [UITextField]!
    
    @IBOutlet var hideContentWarningsToggle: UISwitch!
    @IBOutlet var defaultStatusVisibilityIcon: UIImageView!
    
    @IBOutlet var versionLabel: UILabel!
    @IBOutlet var bugIcon: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.subscriber = Subscriber(state: { $0.accounts }, newState: { (_) in self.updateAccount() })
        self.subscriber.add(state: { $0.storedDefaults }, newState: { (_) in self.updateAccount() })
        
        self.updateAccount()
        
        self.isBotToggle.isOn = self.accountState?.account?.bot ?? false
        self.isLockedToggle.isOn = self.accountState?.account?.locked ?? false
        self.hideContentWarningsToggle.isOn = self.defaultsState.hideContentWarnings
        
        self.versionLabel.text = "\(Bundle.main.version) b\(Bundle.main.build)"
        self.bugIcon.tintColor = .white
    }
    
    @IBAction func dismiss(sender: UIBarButtonItem?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func updateAccount() {
        guard let account = self.accountState?.account else { return }
        
        self.displayNameField.text = account.displayName
        self.avatarView.af_setImage(withURL: URL(string: account.avatar)!)
        self.headerView.af_setImage(withURL: URL(string: account.header)!)
        
        account.fields.enumerated().forEach {
            self.metaLabelFields[$0.offset].text = $0.element.name
            self.metaValueFields[$0.offset].text = String(htmlString: $0.element.value)
        }
        
        switch self.defaultsState.defaultStatusVisibility {
        case .public: self.defaultStatusVisibilityIcon.image = UIImage(named: "PublicButton")
        case .private: self.defaultStatusVisibilityIcon.image = UIImage(named: "PrivateButton")
        case .direct: self.defaultStatusVisibilityIcon.image = UIImage(named: "MessageButton")
        default: break
        }
    }
    
    // MARK: Table View
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath), let id = cell.reuseIdentifier else { return }
        switch id {
        case "AvatarButton": self.avatarButtonWasPressed()
        case "HeaderButton": self.headerButtonWasPressed()
        case "ToggleDefaultStatusVisibilityButton": self.toggleDefaultStatusVisibility()
        case "SubmitBugButton": self.openBugReports()
        case "LogOutButton": self.logout()
        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: Actions
    @IBAction func displayNameFieldDidChange(sender: UITextField?) {
        guard let client = GlobalStore.state.auth.client, let account = self.accountState?.account else { return }
        GlobalStore.dispatch(AccountState.UpdateDisplayName(client: client, account: account, value: self.displayNameField.text ?? ""))
    }
    
    @IBAction func metaFieldDidChange(sender: UITextField?) {
        guard let client = GlobalStore.state.auth.client, let account = self.accountState?.account else { return }
        let fields: [[String: String]] = self.metaLabelFields.enumerated().map {[
            "name": $0.element.text ?? "",
            "value": self.metaValueFields[$0.offset].text ?? ""
        ]}
        
        GlobalStore.dispatch(AccountState.UpdateFields(client: client, account: account, value: fields))
    }
    
    func avatarButtonWasPressed() {
        guard let client = GlobalStore.state.auth.client, let account = self.accountState?.account else { return }
        self.mediaButtonWasPressed {
            GlobalStore.dispatch(AccountState.UpdateAvatar(client: client,
                                                           account: account,
                                                           value: $0))
        }
    }
    
    func headerButtonWasPressed() {
        
    }
    
    private func mediaButtonWasPressed(completion: @escaping (MediaAttachment) -> Void) {
        var config = YPImagePickerConfiguration()
        config.library.mediaType = .photo
        
        config.hidesStatusBar = false
        config.onlySquareImagesFromCamera = false
        config.screens = [.library, .photo]
        config.startOnScreen = .library
        
        config.colors.tintColor = self.view.tintColor
        UINavigationBar.appearance().tintColor = config.colors.tintColor
        
        let picker = YPImagePicker(configuration: config)
        picker.didFinishPicking(completion: { (items, _) in
            picker.dismiss(animated: true, completion: nil)
            
            guard let item = items.first else { return }
            switch item {
            case .photo(p: let photo): completion(.jpeg(photo.image.jpeg(maxSize: ComposeViewController.maxImageFileSize,
                                                                         maxDimensions: ComposeViewController.maxImageSize)))
            default: break
                
            }
        })
        self.present(picker, animated: true, completion: nil)
    }
    
    @IBAction func hideContentWarningsWasToggled(sender: UISwitch?) {
        GlobalStore.dispatch(StoredDefaultsState.SetHideContentWarnings(value: self.hideContentWarningsToggle.isOn))
    }
    
    @IBAction func lockedToggled(sender: UISwitch?) {
        guard let client = GlobalStore.state.auth.client, let account = self.accountState?.account else { return }
        GlobalStore.dispatch(AccountState.UpdateLocked(client: client, account: account, value: self.isLockedToggle.isOn))
    }
    
    func toggleDefaultStatusVisibility() {
        let visibilityPicker = VisibilityPicker { (visibility) in
            GlobalStore.dispatch(StoredDefaultsState.SetDefaultPostVisibility(value: visibility))
        }
        
        self.present(visibilityPicker, animated: true, completion: nil)
    }
    
    // MARK: Navigation
    func openBugReports() {
        let safariVC = SFSafariViewController(url: SettingsViewController.bugURL)
        self.present(safariVC, animated: true, completion: nil)
    }
    
    func logout() {
        let confirmAlert = UIAlertController(title: "Are you sure you want to log out?",
                                             message: nil,
                                             preferredStyle: .alert)
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        confirmAlert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (_) in
            GlobalStore.dispatch(AuthState.ClearAuth())
            self.dismiss(sender: nil)
        }))
        
        self.present(confirmAlert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "PresentComposeViewController": do {
            guard let composeVC = segue.destination as? ComposeContainerViewController else { break }
            composeVC.composeViewController?.isBio = true
            composeVC.composeViewController?.redraft = (
                self.accountState?.account?.note ?? "",
                (self.accountState?.account?.locked ?? false) ? .private : .public
            )
            }
        default: break
        }
    }
}

extension SettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

class SettingsContainerViewController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalPresentationCapturesStatusBarAppearance = true
    }
}
