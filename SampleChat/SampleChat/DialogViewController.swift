//
//  DialogViewController.swift
//  SampleChat
//
//  Created by David on 06.05.2024.
//

import UIKit
import ConnectyCube

class DialogViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var dialogsTable: UITableView!
    @IBOutlet weak var newChatBtn: UIButton!{
        didSet {
            newChatBtn.layer.cornerRadius = newChatBtn.frame.height / 2
            newChatBtn.clipsToBounds = true
        }
    }
    
    @IBAction func newChatBtnAction(_ sender: Any) {
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "UserViewController") as? UserViewController
        vc?.title = "Users"
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    var dialogs: [ConnectycubeDialog] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dialogsTable.register(DialogViewCell.nib(), forCellReuseIdentifier: DialogViewCell.identifier)
        dialogsTable.delegate = self
        dialogsTable.dataSource = self
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: " Logout", style: .plain, target: self, action: #selector(action))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDialogs()
    }
    
    @objc func action (sender:UIButton) {
        logout()
    }
    
    func loadDialogs() {
        ConnectyCube().getDialogs(params: nil, successCallback: { [self] result in
            NSLog("getDialogs result " + result.items.description)
            dialogs = result.items as! [ConnectycubeDialog]
            
            dialogsTable.reloadData()
        }, errorCallback: { error in
            NSLog("getDialogs error " + error.description())
        })
    }
    
    func logout() {
        Task.init {
        try await ConnectyCube().signOut()
            ConnectyCube().chat.logout(successCallback: nil)
            navigationController?.popViewController(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dialogs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DialogViewCell.identifier, for: indexPath) as? DialogViewCell else {
            fatalError("The TableView could not dequeue a DialogViewCell in DialogViewController")
        }
        
        let dialog = dialogs[indexPath.row] as ConnectycubeDialog
        
        cell.nameLabel.text = dialog.name
        cell.messageLabel.text = dialog.lastMessage
        
        var lastMessageDateSent = dialog.lastMessageDateSent
        if (lastMessageDateSent == nil) {
            lastMessageDateSent = DialogDateFormatter.shared.toTimeStamp(dateString: dialog.createdAt!).asXPLong()
        }
             
        cell.dateLabel.text = DialogDateFormatter.shared.toString(dateInt: Int(truncating: lastMessageDateSent!))
        cell.avatarImageView.downloaded(from: dialog.photo ?? "", placeholder: UIImage(named: "avatar_placeholder_group")!)
        
        if(dialog.unreadMessageCount != nil && dialog.unreadMessageCount as! Int > 0 ) {
            cell.counterLabel.isHidden = false
            cell.counterLabel.text = String(dialog.unreadMessageCount as! Int)
        } else {
            cell.counterLabel.isHidden = true
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //show messages
        let dialog: ConnectycubeDialog = dialogs[indexPath.row] as ConnectycubeDialog
        ChatViewController.navigateTo(self, dialog)
    }
}
