//
//  AttachmentItem.swift
//  SampleChat
//
//  Created by David on 05.06.2024.
//

import UIKit
import ConnectyCube
import MessageKit

class AttachmentItem: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    init(connectycubeAttachment: ConnectycubeAttachment) {
        if (connectycubeAttachment.url!.hasPrefix("https")) {
            self.url = URL(string: connectycubeAttachment.url!)
        } else {
            self.url = URL.init(fileURLWithPath: connectycubeAttachment.url!)
        }
       
        if (connectycubeAttachment.width != 0 && connectycubeAttachment.height != 0) {
            size = CGSize(width: Int(connectycubeAttachment.width), height: Int(connectycubeAttachment.height))
        } else {
            self.size = CGSize(width: 240, height: 240)
        }
        self.placeholderImage = UIImage()
    }
}
