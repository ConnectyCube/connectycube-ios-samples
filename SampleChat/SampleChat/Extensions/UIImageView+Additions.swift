//
//  UIImageView+Additions.swift
//  SampleChat
//
//  Created by David on 05.06.2024.
//

import UIKit

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
                DispatchQueue.main.async() { [weak self] in
                    self?.image = image
                }
        }.resume()
    }
    func downloaded(from link: String, placeholder: UIImage, contentMode mode: ContentMode = .scaleToFill) {
        guard let url = URL(string: link) else {
            self.image = placeholder
            return
        }
        downloaded(from: url, contentMode: mode)
    }
    
    func downloadedFile(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            self.image = UIImage(data: data)
        } catch {
        }
    }
    
    func downloaded(from url: URL) {
        if url.isFileURL {
            downloadedFile(from: url)
        } else {
            downloaded(from: url, contentMode: .scaleAspectFit)
        }
    }
}

extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }

    /// Returns the data for the specified image in JPEG format.
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the JPEG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    func jpeg(_ jpegQuality: JPEGQuality) -> Data? {
        return jpegData(compressionQuality: jpegQuality.rawValue)
    }
}

extension UIImageView {
    func configureAvatar(link: String) {
        let itemSize = CGSizeMake(35, 35)
        image = UIImage(systemName: "person.fill.badge.plus")
   
        UIGraphicsBeginImageContextWithOptions(itemSize, false, UIScreen.main.scale)
        let imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height)
        image!.draw(in: imageRect)
        image! = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        layer.cornerRadius = (itemSize.width) / 2
        clipsToBounds = true
        
        downloaded(from: link, placeholder: UIImage(systemName: "person.fill.badge.plus")!)
    }
}

extension UIImageView {
  public func maskCircle() {
      self.contentMode = .scaleAspectFill
      self.layer.cornerRadius = self.frame.height / 2
      self.clipsToBounds = true
  }
}
