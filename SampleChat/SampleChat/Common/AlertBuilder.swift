//
//  AlertBuilder.swift
//  SampleChat
//
//  Created by David on 29.05.2024.
//

import UIKit

class AlertBuilder {
    
    static func showErrorAlert(_ self: UIViewController, _ title: String, _ msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    static func showAlert(_ self: UIViewController, _ title: String, _ msg: String, okHandler: @escaping ((UIAlertAction) -> Void)) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: okHandler))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
