//
//  UserViewCell.swift
//  SampleChat
//
//  Created by David on 28.05.2024.
//

import UIKit

class UserViewCell: UICollectionViewCell {
    
    @IBOutlet weak var avatarImage: UIImageView! {
        didSet {
            avatarImage.layer.masksToBounds = false
            avatarImage.layer.cornerRadius = avatarImage.frame.height / 2
            avatarImage.clipsToBounds = true
        }
    }
    
    @IBOutlet weak var userLable: UILabel!
    
    
}
