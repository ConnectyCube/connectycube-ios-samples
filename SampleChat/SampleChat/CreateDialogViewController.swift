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
    
    let imagePicker = UIImagePickerController()
    
    var avatarPath: String?
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var userCollection: UICollectionView!
    
    @IBOutlet weak var avatarPickImageView: UIImageView!{
        didSet {
            avatarPickImageView.layer.masksToBounds = false
            avatarPickImageView.layer.cornerRadius = avatarPickImageView.frame.width / 2
            avatarPickImageView.clipsToBounds = true
            
            avatarPickImageView.image = UIImage(systemName: "person.circle.fill")
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(CreateDialogViewController.pickImageAction))
            avatarPickImageView.addGestureRecognizer(tap)
            avatarPickImageView.isUserInteractionEnabled = true
        }
    }
    
    @IBOutlet weak var dialogNameLabel: UITextField!
    
    @IBAction func dialogNameAction(_ sender: Any) {
        checkDialogNameExist()
    }
    
    @objc func pickImageAction() {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum
            imagePicker.allowsEditing = false

            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBOutlet weak var checkBtn: UIButton!{
        didSet {
            checkBtn.layer.masksToBounds = false
            checkBtn.layer.cornerRadius = checkBtn.frame.width / 2
            checkBtn.clipsToBounds = true
        }
    }
    @IBAction func checkAction(_ sender: Any) {
        if(checkDialogNameExist)() {
            createDialog()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userCollection.dataSource = self
        userCollection.delegate = self
        spinner.hidesWhenStopped = true
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            avatarPickImageView.contentMode = .scaleAspectFit
            avatarPickImageView.image = pickedImage
            let url = info[UIImagePickerController.InfoKey.imageURL] as? URL
            avatarPath = url?.path
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        selectedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "userCell", for: indexPath) as! UserViewCell
        let user = selectedUsers[indexPath.row]
        cell.userLable.text = user.fullName
        cell.avatarImage.downloaded(from: user.avatar ?? "", placeholder: UIImage(systemName: "person")!)
        
        return cell
    }
    
    func checkDialogNameExist() -> Bool {
        if let text = dialogNameLabel.text, text.isEmpty {
            AlertBuilder.showErrorAlert(self, "Error", "Dialog name can't be empty")
            return false
        }
        return true
    }
    
    func stopInteraction() {
        spinner.startAnimating()
        view.isUserInteractionEnabled = false
    }
    
    func startInteraction() {
        spinner.stopAnimating()
        view.isUserInteractionEnabled = true
    }
    
    func createDialog() {
        
        let dialog = ConnectycubeDialog()
        dialog.type = ConnectycubeDialogType.companion.GROUP
        dialog.occupantsIds = ((selectedUsers.map{$0.id} as NSArray).mutableCopy() as! NSMutableArray)
        dialog.name = dialogNameLabel.text
        

        Task.init {
            do {
                stopInteraction()
                if(avatarPath != nil) {
                    let file = try await ConnectyCube().uploadFile(filePath: avatarPath!, public: true, progress: nil)
                    dialog.photo = file.getPublicUrl()
                }
                let dialog = try await ConnectyCube().createDialog(connectycubeDialog: dialog)
                startInteraction()
                ChatViewController.navigateTo(self, dialog)
            } catch let error {
                AlertBuilder.showErrorAlert(self, "Error", "create dialog: \(error.localizedDescription)")
            }
        }
    }
    
}
