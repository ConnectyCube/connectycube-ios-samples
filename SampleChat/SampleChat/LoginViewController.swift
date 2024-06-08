//
//  LoginViewController.swift
//  SampleChat
//
//  Created by David on 30.04.2024.
//

import UIKit
import ConnectyCube

class LoginViewController: UIViewController {
    
    @IBOutlet weak var loginTextView: UITextField!
    
    @IBOutlet weak var pswTextView: UITextField!
    
    @IBOutlet weak var signInUpBtn: UIButton!
    
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var signInUpHintBtn: UIButton!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.hidesWhenStopped = true
        
        makeLogin()
    }
    
    @IBAction func signInUpAction(_ sender: UIButton) {
        let user = ConnectycubeUser()
        user.login = loginTextView.text
        user.password = pswTextView.text
        
        stopInteraction(spinner, view)
        if(signInUpBtn.isSelected) {
            NSLog("Sign up")
            signUp(user)
        } else {
            NSLog("Log in")
            signIn(user)
        }
    }
    
    @IBAction func signInUpHintAction(_ sender: UIButton) {
        if(sender.isSelected) {
            sender.setTitle("Sign up", for: .normal)
            infoLabel.text = "Don't have an account?"
            signInUpBtn.setTitle("Log in", for: .normal)
        } else {
            sender.setTitle("Sign in", for: .normal)
            infoLabel.text = "Already have an account?"
            signInUpBtn.setTitle("Sign up", for: .normal)
        }
        signInUpBtn.isSelected = !signInUpBtn.isSelected
        sender.isSelected = !sender.isSelected
    }
    
    func makeLogin() {
        if(UserDefaultsManager.shared.currentUserExists()) {
            signInUpBtn.isEnabled = false
            spinner.startAnimating()
            let user = UserDefaultsManager.shared.getCurrentUser()
            if(isSignedIn(user!)) {
                loginToChat(user!)
            } else {
                signIn(user!)
            }
        } else {
            signInUpBtn.isEnabled = true
        }
    }
    
    func isSignedIn(_ user: ConnectycubeUser) -> Bool {
        ConnectycubeSessionManager.shared.activeSession?.user?.id == user.id
    }
    
    func signIn(_ user: ConnectycubeUser) {
        print("createSession on \(Thread.current)")
        ConnectyCube().createSession(user: user, successCallback: { session in
            NSLog("Created session is " + session.description())
            user.id = session.userId as! Int32
            UserDefaultsManager.shared.saveCurrentUser(user)
            self.loginToChat(user)
        }, errorCallback: { error in
            NSLog("error" + error.description())
        })
    }
    
    func signUp(_ user: ConnectycubeUser) {
        Task.init {
            do {
                try await ConnectyCube().createSession(user: nil)
                try await ConnectyCube().signIn(user: user)

            } catch let error {
                print("signOut error" + error.localizedDescription)
            }
        }
    }

    func loginToChat(_ user: ConnectycubeUser) {
        print("loginToChat on \(Thread.current)")
        ConnectyCube().chat.login(user: user, successCallback:{ [self] in
            NSLog("chat login success")
            startInteraction(spinner, view)
            self.navigateToDialogs()
        }, errorCallback: { error in
            NSLog("chat login error= " + error.description())
        }, resource: ConnectycubeSettings().chatDefaultResource)
    }
    
    func navigateToDialogs() {
        print("navigateToDialogs on \(Thread.current)")
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "DialogViewController") as? DialogViewController
        vc?.title = "Dialogs"
        vc?.navigationItem.prompt = ConnectycubeSessionManager().activeSession!.user!.login
        self.navigationController?.pushViewController(vc!, animated: true)
    }
}
