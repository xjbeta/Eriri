//
//  VideoView.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/20.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import SwiftUI
import AppKit

struct VideoView: NSViewRepresentable {
    
    let videoView = VLCVideoView()
    let player: VLCMediaPlayer
    
    func makeNSView(context: Context) -> VLCVideoView {
        player.videoView = videoView
        player.play()
        return videoView
    }
    
    func updateNSView(_ nsView: VLCVideoView, context: Context) {
        
    }
}

