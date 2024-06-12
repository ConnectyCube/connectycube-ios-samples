//
//  ChatDetailsViewController.swift
//  SampleChat
//
//  Created by David on 08.06.2024.
//

import UIKit
import ConnectyCube

class ChatDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var currentDialog: ConnectycubeDialog?
    var loadedUsers: [ConnectycubeUser] = []
 
    var pickerManager: UIImagePickerManager?
    
    var addedUsers: [ConnectycubeUser] = []
    
    @IBOutlet weak var photoImageView: UIImageView!{
        didSet {
            photoImageView.maskCircle()
            photoImageView.downloaded(from: currentDialog!.photo ?? "", placeholder: UIImage(named: "avatar_placeholder_group")!)
        }
    }  
    
    @IBOutlet weak var nameTextView: UITextField!{
        didSet {
            nameTextView.text = currentDialog?.name
        }
    }

    @IBOutlet weak var usersTable: UITableView!
    
    @IBOutlet weak var checkBtn: UIButton!{
        didSet {
            checkBtn.layer.cornerRadius = checkBtn.frame.height / 2
            checkBtn.clipsToBounds = true
        }
    }
    
    @IBAction func checkAction(_ sender: Any) {
        if canBeUpdated() {
            updateDialog()
        } else {
            AlertBuilder.showErrorAlert(self, "Error", "Dialog's params can't be empty")
        }
    }
    
    @IBOutlet weak var circleImageView: UIImageView!{
        didSet {
            circleImageView.maskCircle()
        }
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerManager = UIImagePickerManager(vc: self, imageView: photoImageView)

        usersTable.register(UITableViewCell.self, forCellReuseIdentifier: "userCell")
        usersTable.delegate = self
        usersTable.dataSource = self
        
        spinner.hidesWhenStopped = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        usersTable.reloadData()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        pickerManager!.imagePickerController(didFinishPickingMediaWithInfo: info)
    }
    
    func customLabel(view: UIView, text: String) -> UILabel {
        let label = UILabel()
        label.frame = CGRect.init(x: 60, y: 5, width: view.frame.width-10, height: view.frame.height-10)
        label.text = text
        label.font = .boldSystemFont(ofSize: 16)
        return label
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loadedUsers.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
        let imageView = UIImageView(frame: CGRect.init(x: 10, y: 5, width: 35, height: 35))
        imageView.image = UIImage(systemName: "person.fill.badge.plus")

        headerView.addSubview(imageView)
        headerView.addSubview(customLabel(view: headerView, text: "Add member"))

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleHeaderTap))
        headerView.addGestureRecognizer(tap)
        headerView.isUserInteractionEnabled = true

        return headerView
    }
    
    @objc func handleHeaderTap(_ sender: UITapGestureRecognizer) {
        let vc = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "UserSearchViewController") as? UserSearchViewController
        vc?.title = "Users"
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
        let imageView = UIImageView(frame: CGRect.init(x: 10, y: 5, width: 35, height: 35))
        imageView.image = UIImage(systemName: "rectangle.portrait.and.arrow.right")

        footerView.addSubview(imageView)
        footerView.addSubview(customLabel(view: footerView, text: "Exit group"))
            
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleFooterTap))
        footerView.addGestureRecognizer(tap)
        footerView.isUserInteractionEnabled = true
        
        return footerView
    }
    
    @objc func handleFooterTap(_ sender: UITapGestureRecognizer) {
        AlertBuilder.showAlert(self, "Exit chat", "Are you sure you want to leave the group chat?", okHandler: { [self] (action: UIAlertAction!) in
            Task.init {
                do {
                    stopInteraction(spinner, view)
                    try await ConnectyCube().deleteDialog(dialogId: currentDialog!.dialogId!, force: false)
                    startInteraction(spinner, view)
                    navigationController?.popToViewController(ofClass: DialogViewController.self)
                } catch let error {
                    startInteraction(spinner, view)
                    AlertBuilder.showErrorAlert(self, "Error", "exit chat: \(error.localizedDescription)")
                }
            }
        })
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath)
        let user = loadedUsers[indexPath.row]
        cell.textLabel!.text = user.fullName ?? user.login
        cell.imageView!.configureAvatar(link: user.avatar ?? "")
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UserProfileViewController.navigateTo(self, loadedUsers[indexPath.row])
    }
    
    func canBeUpdated() -> Bool {
        return (!nameTextView.text!.isEmpty && nameTextView.text! != currentDialog!.name) || !addedUsers.isEmpty || pickerManager?.imagePath != nil
    }
    
    func updateDialog() {
        let paramsToUpdate = UpdateDialogParams()
        if !nameTextView.text!.isEmpty {
            paramsToUpdate.newName = nameTextView.text
        }
        if !addedUsers.isEmpty {
            paramsToUpdate.addOccupantIds.add(Set(addedUsers.map{$0.id}))
        }
        Task.init {
            do {
                stopInteraction(spinner, view)
                if(pickerManager?.imagePath != nil) {
                    let file = try await ConnectyCube().uploadFile(filePath: (pickerManager?.imagePath)!, public: true, progress: nil)
                    paramsToUpdate.newPhoto = file.getPublicUrl()
                }
                let parameters = paramsToUpdate.getUpdateDialogParams() as! [String : Any]
                let dialog = try await ConnectyCube().updateDialog(dialogId: currentDialog!.dialogId!, params: parameters)
                startInteraction(spinner, view)
                navigationController?.popToViewController(ofClass: DialogViewController.self)
            } catch let error {
                startInteraction(spinner, view)
                AlertBuilder.showErrorAlert(self, "Error", "update dialog: \(error.localizedDescription)")
            }
        }
    }
}
