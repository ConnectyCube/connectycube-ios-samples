//
//  UserProfileViewController.swift
//  SampleChat
//
//  Created by David on 11.06.2024.
//

import UIKit
import ConnectyCube

class UserProfileViewController: UIViewController {
    
    var user: ConnectycubeUser?
    
    @IBOutlet weak var spinner: UIActivityIndicatorView! {
        didSet {
            spinner.hidesWhenStopped = true
        }
    }
    
    @IBOutlet weak var userNameLabel: UITextField! {
        didSet {
            userNameLabel.text = user?.fullName ?? user?.login
        }
    }
    
    @IBOutlet weak var chatBtn: UIButton!
    
    
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
