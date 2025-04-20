//
//  VideoStreamView.swift
//  Rasberry Pi Camera
//
//  Created by Dave Kanter on 3/16/25.
//


// for displaying the video stream

import SwiftUI
import AVKit

struct VideoStreamView: UIViewControllerRepresentable {
    @EnvironmentObject var streamManager: StreamManager

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect

        if let url = streamManager.getStreamURL() {
            let player = AVPlayer(url: url)
            controller.player = player
            player.play()
        }
        
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if let url = streamManager.getStreamURL(),
            (uiViewController.player?.currentItem?.asset as? AVURLAsset)?.url != url {
                let player = AVPlayer(url: url)
                uiViewController.player = player
                player.play()
            }
    }
}
