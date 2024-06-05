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
