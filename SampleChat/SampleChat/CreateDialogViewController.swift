//
//  CreateDialogController.swift
//  SampleChat
//
//  Created by David on 25.05.2024.
//

import UIKit
import ConnectyCube

class CreateDialogViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var selectedUsers: [ConnectycubeUser] = []
    
    var pickerManager: UIImagePickerManager?
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var userCollection: UICollectionView!
    
    @IBOutlet weak var avatarPickImageView: UIImageView!{
        didSet {
            avatarPickImageView.maskCircle()
            avatarPickImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }
    
    @IBOutlet weak var dialogNameLabel: UITextField!
    
    @IBAction func dialogNameAction(_ sender: Any) {
        checkDialogNameExist()
    }
    
    @IBOutlet weak var checkBtn: UIButton!{
        didSet {
            checkBtn.layer.masksToBounds = false
            checkBtn.layer.cornerRadius = checkBtn.frame.width / 2
            checkBtn.clipsToBounds = true
        }
    }
    @IBAction func checkAction(_ sender: Any) {
        if(checkDialogNameExist() && checkSelectedUsers()) {
            createDialog()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerManager = UIImagePickerManager(vc: self, imageView: avatarPickImageView)
        userCollection.dataSource = self
        userCollection.delegate = self
        spinner.hidesWhenStopped = true
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        pickerManager!.imagePickerController(didFinishPickingMediaWithInfo: info)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        selectedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "userCell", for: indexPath) as! UserViewCell
        let user = selectedUsers[indexPath.row]
        cell.userLable.text = user.login
        cell.avatarImageView.downloaded(from: user.avatar ?? "", placeholder: UIImage(systemName: "person")!)
        cell.removeUserPressed = {
            self.selectedUsers.removeAll{$0 == user}
            self.userCollection.reloadData()
        }
        return cell
    }
    
    func checkDialogNameExist() -> Bool {
        if let text = dialogNameLabel.text, text.isEmpty {
            AlertBuilder.showErrorAlert(self, "Error", "Dialog name can't be empty")
            return false
        }
        return true
    }
    
    func checkSelectedUsers() -> Bool {
        if (selectedUsers.isEmpty) {
            AlertBuilder.showErrorAlert(self, "Error", "Dialog occupants can't be empty")
            return false
        }
        return true
    }
    
    func createDialog() {
        let dialog = ConnectycubeDialog()
        dialog.type = ConnectycubeDialogType.companion.GROUP
        dialog.occupantsIds = ((selectedUsers.map{$0.id} as NSArray).mutableCopy() as! NSMutableArray)
        dialog.name = dialogNameLabel.text

        Task.init {
            do {
                stopInteraction(spinner, view)
                if(pickerManager!.imagePath != nil) {
                    let file = try await ConnectyCube().uploadFile(filePath: pickerManager!.imagePath!, public: true, progress: nil)
                    dialog.photo = file.getPublicUrl()
                }
                let dialog = try await ConnectyCube().createDialog(connectycubeDialog: dialog)
                startInteraction(spinner, view)
                ChatViewController.navigateTo(self, dialog)
            } catch let error {
                AlertBuilder.showErrorAlert(self, "Error", "create dialog: \(error.localizedDescription)")
            }
        }
    }
}
