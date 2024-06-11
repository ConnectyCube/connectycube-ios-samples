//
//  UserProfileViewController.swift
//  SampleChat
//
//  Created by David on 11.06.2024.
//

import UIKit
import ConnectyCube

class UserProfileViewController: UIViewController {
    
    static func navigateTo(_ controller: UIViewController, _ user: ConnectycubeUser) {
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "UserProfileViewController") as? UserProfileViewController
        vc?.title = "User Profile"
        vc?.user = user
        controller.navigationController?.pushViewController(vc!, animated: true)
    }
    
    var user: ConnectycubeUser?
    
    @IBOutlet weak var spinner: UIActivityIndicatorView! {
        didSet {
            spinner.hidesWhenStopped = true
        }
    }
    
    @IBOutlet weak var avatarImageView: UIImageView! {
        didSet {
            avatarImageView.configureAvatar(link: user!.avatar ?? "", itemSize: CGSizeMake(70, 70))
        }
    }
    
    @IBOutlet weak var userNameLabel: UITextField! {
        didSet {
            userNameLabel.text = user?.fullName ?? user?.login
        }
    }
       
    
    @IBAction func chatAction(_ sender: Any) {
        stopInteraction(spinner, view)
        let dialog = ConnectycubeDialog()
        dialog.type = ConnectycubeDialogType.companion.PRIVATE
        dialog.occupantsIds = [user?.id ?? 0]
        
        ConnectyCube().createDialog(connectycubeDialog: dialog, successCallback: { [self] dialog in
            ChatViewController.navigateTo(self, dialog)
        }, errorCallback: { [self] error in
            startInteraction(spinner, view)
            AlertBuilder.showErrorAlert(self, "Error", "create dialog: \(error.description())")
        })
    }
}
