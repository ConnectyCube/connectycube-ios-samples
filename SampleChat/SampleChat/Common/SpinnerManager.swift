//
//  SpinnerManager.swift
//  SampleChat
//
//  Created by David on 09.06.2024.
//

import UIKit

func stopInteraction(_ spinner: UIActivityIndicatorView, _ view: UIView) {
    spinner.startAnimating()
    view.isUserInteractionEnabled = false
}

func startInteraction(_ spinner: UIActivityIndicatorView, _ view: UIView) {
    spinner.stopAnimating()
    view.isUserInteractionEnabled = true
}
