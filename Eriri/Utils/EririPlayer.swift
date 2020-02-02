//
//  EririPlayer.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/29.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import VLCKit
import SwiftUI

class WindowSize: ObservableObject, Identifiable {
    let id = UUID()
    @Published var size: CGSize = .zero
}

class EririPlayer: NSObject {
    let window = NSWindow()
    let player = VLCMediaPlayer()
    let windowSize = WindowSize()
    
    init(_ url: URL) {
        super.init()
        let windowMinSize = CGSize(width: 480, height: 270)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        player.media = .init(url: url)
        
        let contentView = ContentView(window: window, player: player, windowSize: windowSize)
        
        window.minSize = windowMinSize
        window.isMovableByWindowBackground = true
        window.contentView = NSHostingView(rootView: contentView)
        window.setTitleWithRepresentedFilename(url.path)
        window.delegate = self
    }
}

extension EririPlayer: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        player.stop()
        if let videoView = player.drawable as? VLCVideoView {
            videoView.trackingAreas.forEach {
                videoView.removeTrackingArea($0)
            }
        }
        (player.delegate as? VideoView.Coordinator)?.timer.stop()
        player.delegate = nil
        NSCursor.unhide()
        Utils.shared.players.removeAll(where: {
            $0 == self
        })
        return true
    }

    func windowDidResize(_ notification: Notification) {
        windowSize.size = window.frame.size
    }
}
