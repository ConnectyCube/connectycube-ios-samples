//
//  UserSearchViewController.swift
//  SampleChat
//
//  Created by David on 10.06.2024.
//

import UIKit
import ConnectyCube

class UserSearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var loadedUsers: [ConnectycubeUser] = []
    var selectedUsers: [ConnectycubeUser] = []

    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var usersTable: UITableView!
    
    @IBOutlet weak var checkBtn: UIButton!{
        didSet {
            checkBtn.layer.cornerRadius = checkBtn.frame.height / 2
            checkBtn.clipsToBounds = true
        }
    }
    
    @IBAction func checkAction(_ sender: Any) {
        navigateToChatDetails()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        usersTable.register(UITableViewCell.self, forCellReuseIdentifier: "userCell")
        usersTable.delegate = self
        usersTable.dataSource = self
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
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
        cell.accessoryType = selectedUsers.contains(user) ? .checkmark : .none
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
        checkBtn.isHidden = selectedUsers.isEmpty
        usersTable.reloadData()
    }
    
    func navigateToChatDetails() {
        if let vc = navigationController!.viewControllers.last(where: { $0.isKind(of: ChatDetailsViewController.self) }) {
            let vc = vc as! ChatDetailsViewController
            vc.loadedUsers.append(contentsOf: selectedUsers)
            vc.addedUsers.append(contentsOf: selectedUsers)
            navigationController!.popToViewController(vc, animated: true)
        }
    }
}
