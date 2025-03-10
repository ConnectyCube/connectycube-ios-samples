//
//  LoginViewController.swift
//  SampleVideoChat
//
//  Created by David on 10.10.2023.
//

import UIKit
import ConnectyCube

class LoginViewController: UIViewController {
    let APP_ID = "REPLACE_APP_ID"
    let AUTH_KEY = "REPLACE_APP_AUTH_KEY"
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    let user1: ConnectycubeUser = ConnectycubeUser().apply{
        $0.login = "REPLACE_USER_1_LOGIN"
        $0.password = "REPLACE_USER_1_PASSWORD"
        $0.id = Int32("REPLACE_USER_1_ID")!
        $0.fullName = "REPLACE_USER_1_FULL_NAME"
    }
    let user2: ConnectycubeUser = ConnectycubeUser().apply{
        $0.login = "REPLACE_USER_2_LOGIN"
        $0.password = "REPLACE_USER_2_PASSWORD"
        $0.id = Int32("REPLACE_USER_2_ID")!
        $0.fullName = "REPLACE_USER_2_FULL_NAME"
    }
    let user3: ConnectycubeUser = ConnectycubeUser().apply{
        $0.login = "REPLACE_USER_3_LOGIN"
        $0.password = "REPLACE_USER_3_PASSWORD"
        $0.id = Int32("REPLACE_USER_3_ID")!
        $0.fullName = "REPLACE_USER_3_FULL_NAME"
    }
    let user4: ConnectycubeUser = ConnectycubeUser().apply{
        $0.login = "REPLACE_USER_4_LOGIN"
        $0.password = "REPLACE_USER_4_PASSWORD"
        $0.id = Int32("REPLACE_USER_4_ID")!
        $0.fullName = "REPLACE_USER_4_FULL_NAME"
    }
    
    var users: Array<ConnectycubeUser> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ConnectyCube().doInit(applicationId: APP_ID, authorizationKey: AUTH_KEY, connectycubeConfig: nil)
        ConnectycubeSettings().isDebugEnabled = true
        ConnectyCube().chat.enableLogging()
        
        users = [user1, user2, user3, user4]
        tableView.delegate = self
        tableView.dataSource = self
        spinner.hidesWhenStopped = true
    }
    
    func loginToChat(user: ConnectycubeUser, usersToSelect: Array<ConnectycubeUser> = []) {
        spinner.startAnimating()
        view.isUserInteractionEnabled = false
        ConnectyCube().chat.login(user: user, successCallback:{ [self] in
            NSLog("chat login success")
            self.spinner.stopAnimating()
            self.view.isUserInteractionEnabled = true
            RTCSessionManager.shared.register(usersToSelect)
            navigateToStartCall(currentUser: user, usersToSelect: usersToSelect)
        }, errorCallback: { error in
            NSLog("chat login error= " + error.description())
            self.showErrorAlert("Chat login error", error.message ?? "")
            self.spinner.stopAnimating()
            self.view.isUserInteractionEnabled = true
        }, resource: ConnectycubeSettings().chatDefaultResource)
    }
    
    func showErrorAlert(_ title: String, _ msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func navigateToStartCall(currentUser: ConnectycubeUser, usersToSelect: Array<ConnectycubeUser> = []) {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "StartCallViewController") as! StartCallViewController
        vc.currentUser = currentUser
        vc.users = usersToSelect
        vc.navigationItem.prompt = currentUser.fullName
        
        let navController = UIApplication.shared.firstKeyWindow?.rootViewController as? UINavigationController
        navController!.pushViewController(vc, animated: true)
    }
}

extension LoginViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        checkCredentials()
        loginToChat(user: users[indexPath.section], usersToSelect: users.filter{$0 != users[indexPath.section]})
    }
    
    func checkCredentials() {
        if(APP_ID.isEmpty || AUTH_KEY.isEmpty) {
            assertionFailure("The LoginViewController should contain ConnectyCube credentials")
        }
    }
}

extension LoginViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let userCell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath)
        userCell.textLabel?.text = users[indexPath.section].fullName
        userCell.textLabel?.textAlignment = .center
        return userCell
    }
}

protocol HasApply { }

extension HasApply {
    func apply(closure:(Self) -> ()) -> Self {
        closure(self)
        return self
    }
}
extension NSObject: HasApply { }

extension UIApplication {
    var firstKeyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .first?.keyWindow

    }
}
