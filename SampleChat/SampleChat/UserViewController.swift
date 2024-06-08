//
//  UserViewController.swift
//  SampleChat
//
//  Created by David on 20.05.2024.
//

import UIKit
import ConnectyCube

class UserViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var chatSwitchBtn: UIButton!
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var usersTable: UITableView!
    @IBOutlet weak var checkBtn: UIButton!{
        didSet {
            checkBtn.layer.cornerRadius = checkBtn.frame.height / 2
            checkBtn.clipsToBounds = true
        }
    }
    
    @IBAction func checkAction(_ sender: Any) {
        if(!selectedUsers.isEmpty) {
            actionCreateDialog(false)
        }
    }
    
    @IBAction func chatSwitchAction(_ sender: UIButton) {
        if(sender.isSelected) {
            sender.setTitle("Switch to group chat creation", for: .normal)
        } else {
            sender.setTitle("Switch to private chat creation", for: .normal)
        }
        
        isPrivateChat = !isPrivateChat
        usersTable.reloadData()
        sender.isSelected = !sender.isSelected
    }
    
    var isPrivateChat = true
    
    var loadedUsers: [ConnectycubeUser] = []
    var selectedUsers: [ConnectycubeUser] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        usersTable.register(UITableViewCell.self, forCellReuseIdentifier: "userCell")
        usersTable.delegate = self
        usersTable.dataSource = self
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("searchText \(searchBar.text ?? "empty")")
        searchBar.endEditing(true)
        if(searchBar.text?.count ?? 1 <= 3) {
            AlertBuilder.showErrorAlert(self, "Error", "Enter more than 3 charactes")
        } else {
            loadUsers(username: searchBar.text!, function:{ [self] (users) -> Void in
                loadedUsers.removeAll()
                selectedUsers.removeAll()
                loadedUsers.append(contentsOf: users)
                usersTable.reloadData()
            })
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loadedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath)
        let user = loadedUsers[indexPath.row]
        cell.textLabel!.text = user.fullName
        cell.imageView!.configureAvatar(link: user.avatar ?? "")
        if(isPrivateChat) {
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.accessoryType = selectedUsers.contains(user) ? .checkmark : .none
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = loadedUsers[indexPath.row]

        if(selectedUsers.contains(user)) {
            let index = selectedUsers.firstIndex(of: user)
            selectedUsers.remove(at: index!)
        } else {
            selectedUsers.append(user)
        }
        
        if(isPrivateChat) {
            actionCreateDialog(true)
            return
        } else {
            checkBtn.isHidden = selectedUsers.isEmpty
        }
        usersTable.reloadData()
    }
    
    func actionCreateDialog(_ isPrivate: Bool) {
        if (!isPrivate) {
            let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "CreateDialogViewController") as? CreateDialogViewController
            vc?.selectedUsers = selectedUsers
            vc?.title = "Dialog detail"
            NSLog("navigationController pushViewController CreateDialogViewController")
            navigationController?.pushViewController(vc!, animated: true)
        }
        else {
            createDialog()
        }
    }
    
    func createDialog() {
        print("create new dialog \(selectedUsers.count)")
        let dialog = ConnectycubeDialog()
        dialog.type = ConnectycubeDialogType.companion.PRIVATE
        dialog.occupantsIds = ((selectedUsers.map{$0.id} as NSArray).mutableCopy() as! NSMutableArray)
        
        ConnectyCube().createDialog(connectycubeDialog: dialog, successCallback: { [self] dialog in
            ChatViewController.navigateTo(self, dialog)
        }, errorCallback: { error in
            NSLog("createDialog error " + error.description())
        })
    }
}
