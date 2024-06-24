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

extension UIImageView {
    func configureAvatar(link: String, itemSize: CGSize = CGSizeMake(35, 35)) {
        if(link.isEmpty) {
            image = UIImage(systemName: "person.fill")
            return
        }
        image = UIImage()
        UIGraphicsBeginImageContextWithOptions(itemSize, false, UIScreen.main.scale)
        let imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height)
        image!.draw(in: imageRect)
        image! = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        layer.cornerRadius = (itemSize.width) / 2
        clipsToBounds = true
        
        downloaded(from: link, placeholder: UIImage(systemName: "person.fill")!)
    }
}

extension UIImageView {
  public func maskCircle() {
      self.contentMode = .scaleAspectFill
      self.layer.cornerRadius = self.frame.height / 2
      self.clipsToBounds = true
  }
}
