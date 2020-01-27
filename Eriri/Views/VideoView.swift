//
//  VideoView.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/20.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import SwiftUI
import AppKit
import VLCKit

struct VideoView: NSViewRepresentable {
    
    let videoView = VLCVideoView()
    
    @Binding var isPlaying: Bool
    //    @Binding var windowTitle: String
    
    @Binding var leftTime: String
    @Binding var rightTime: String
    @Binding var videoSize: CGSize
    @Binding var position: Float
    @Binding var volumePosition: Float
    @Binding var windowIsResizing: Bool
    
    let player: VLCMediaPlayer
    let window: NSWindow
    
    func makeNSView(context: Context) -> VLCVideoView {
        player.delegate = context.coordinator
        player.setVideoView(videoView)
        player.media.delegate = context.coordinator
        player.play()
        return videoView
    }
    
    func updateNSView(_ nsView: VLCVideoView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, VLCMediaPlayerDelegate, VLCMediaDelegate, NSWindowDelegate {
        var control: VideoView
        var volumeObserver: NSKeyValueObservation?
        init(_ control: VideoView) {
            self.control = control
        }
        
        // MARK: - VLCMediaPlayerDelegate
        func mediaPlayerStateChanged(_ aNotification: Notification!) {
            if volumeObserver == nil {
                volumeObserver = control.player.observe(\.audio.volume, options: [.initial, .new]) { (player, _) in
                    self.control.volumePosition = Float(player.audio.volume / 100)
                }
            }
            switch control.player.state {
            case .opening:
                print(#function, "opening")
            case .playing:
                print(#function, "playing")
            case .paused:
                print(#function, "paused")
            case .stopped:
                print(#function, "stopped")
            case .buffering:
                print(#function, "buffering")
            case .ended:
                print(#function, "ended")
            case .error:
                print(#function, "error")
            case .esAdded:
                print(#function, "esAdded")
            @unknown default:
                print(#function, "unknown")
            }
            
            
            control.volumePosition = Float(control.player.audio.volume / 100)
            
            control.isPlaying = control.player.isPlaying
            
            print(control.player.titleDescriptions)
            
            let d = control.player.media.metaDictionary
            print(d)
            let i = control.player.media.tracksInformation
            print(i)
        }
        
        func mediaPlayerTimeChanged(_ aNotification: Notification!) {
            control.leftTime = control.player.time.stringValue
            control.rightTime = control.player.remainingTime.stringValue
            control.position = control.player.position
            
            //            print("fps: \(control.player.framesPerSecond)")
            //            VLCMediaTracksInformationFrameRate
            
            
        }
        
        func mediaPlayerTitleChanged(_ aNotification: Notification!) {
            print(#function, control.player.titleDescriptions)
        }
        
        func mediaPlayerChapterChanged(_ aNotification: Notification!) {
            print(#function)
            
        }
        
        // MARK: - VLCMediaDelegate
        func mediaMetaDataDidChange(_ aMedia: VLCMedia) {
            print(#function, aMedia.metaDictionary)
        }
        
        func mediaDidFinishParsing(_ aMedia: VLCMedia) {
            let videoSize = control.player.videoSize
            control.videoSize = videoSize
            control.window.delegate = self
            updateWindowFrame()
        }
        
        func windowWillClose(_ notification: Notification) {
            control.player.stop()
        }
        
        func windowWillStartLiveResize(_ notification: Notification) {
            print(#function)
            control.windowIsResizing = true
        }
        
        func windowDidEndLiveResize(_ notification: Notification) {
            print(#function)
            control.windowIsResizing = false
        }
        
        
        func updateWindowFrame() {
            let videoSize = control.player.videoSize
            if control.window.contentAspectRatio != videoSize {
                control.window.contentAspectRatio = videoSize
                
                let p = control.window.frame.origin
                var rect = NSRect(x: p.x, y: p.y, width: videoSize.width, height: videoSize.height)
                if let sSize = NSScreen.main?.frame.size {
                    let rate = rect.width / rect.height
                    if rect.width > sSize.width {
                        rect.size.width = sSize.width
                        rect.size.height = rect.width / rate
                    }
                    
                    if rect.height > sSize.height {
                        rect.size.height = sSize.height
                        rect.size.width = sSize.height * rate
                    }
                }
                control.window.setFrame(rect, display: true)
                control.window.center()
                control.window.makeKeyAndOrderFront(nil)
            }
        }
    }
}
