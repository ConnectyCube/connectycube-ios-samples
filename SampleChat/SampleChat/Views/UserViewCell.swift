//
//  UserViewCell.swift
//  SampleChat
//
//  Created by David on 28.05.2024.
//

import UIKit

class UserViewCell: UICollectionViewCell {
    
    @IBOutlet weak var avatarImageView: UIImageView! {
        didSet {
            avatarImageView.layer.masksToBounds = false
            avatarImageView.layer.cornerRadius = avatarImageView.frame.height / 2
            avatarImageView.clipsToBounds = true
        }
    }
    
    @IBOutlet weak var userLable: UILabel!
    
    
}
