//
//  DialogViewCell.swift
//  SampleChat
//
//  Created by David on 16.05.2024.
//

import UIKit

class DialogViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var counterLabel: CounterLabel!
    
    @IBOutlet weak var avatarImageView: UIImageView! {
        didSet {
            configureImage(avatarImageView)
        }
    }    
    
    static let identifier = "DialogViewCell"
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    func configureImage(_ imageView: UIImageView) {
        imageView.image = UIImage(named: "avatar_placeholder_group")
        imageView.layer.masksToBounds = false
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
        imageView.clipsToBounds = true
    }
}
