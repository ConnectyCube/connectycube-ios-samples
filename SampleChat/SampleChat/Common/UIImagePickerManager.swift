//
//  UIImagePickerManager.swift
//  SampleChat
//
//  Created by David on 09.06.2024.
//

import UIKit

class UIImagePickerManager {
    
    let vc: UIViewController
    var imageView: UIImageView
    var imagePath: String?
    
    let imagePicker = UIImagePickerController()
    
    init(vc: UIViewController, imageView: UIImageView) {
        self.vc = vc
        self.imageView = imageView
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(pickImageAction))
        imageView.addGestureRecognizer(tap)
        imageView.isUserInteractionEnabled = true
    }
    
    @objc func pickImageAction() {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            let flag = vc is any UIImagePickerControllerDelegate & UINavigationControllerDelegate
            imagePicker.delegate = (vc as! any UIImagePickerControllerDelegate & UINavigationControllerDelegate)
            imagePicker.sourceType = .savedPhotosAlbum
            imagePicker.allowsEditing = false

            vc.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    public func imagePickerController(didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.maskCircle()
            imageView.image = pickedImage
            let url = info[UIImagePickerController.InfoKey.imageURL] as? URL
            imagePath = url!.path
        }
        vc.dismiss(animated: true, completion: nil)
    }
}
