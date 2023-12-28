//
//  CollectionViewCell.swift
//  SampleVideoChat
//
//  Created by David on 26.12.2023.
//

import UIKit
import WebRTC

class CollectionViewCell: UICollectionViewCell {

    func configureVideo(with videoView: RTCMTLVideoView) {
        setupVideo(videoView)
    }
    
    private func setupVideo(_ videoView: RTCMTLVideoView) {
        insertSubview(videoView, at: 0)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        videoView.videoContentMode = .scaleAspectFill
        videoView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        videoView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        videoView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        videoView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    }
}
