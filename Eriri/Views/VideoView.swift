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
    
    let videoView = MovableVideoView()
    
    @Binding var isPlaying: Bool
    @Binding var leftTime: String
    @Binding var rightTime: String
    @Binding var videoSize: CGSize
    @Binding var position: Float
    @Binding var volumeValue: Float
    @Binding var hideVCV: Bool
    @Binding var vcvIsDragging: Bool
    
    let player: VLCMediaPlayer
    let window: NSWindow
    
    func makeNSView(context: Context) -> MovableVideoView {
        player.delegate = context.coordinator
        player.setVideoView(videoView)
        player.media.delegate = context.coordinator
        player.play()
        return videoView
    }
    
    
    func updateNSView(_ nsView: MovableVideoView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func hideTitleAndVCV(_ hide: Bool, onlyVCV: Bool = false) {
        if !onlyVCV {
            window.hideTitlebar(hide)
        }
        hideVCV = hide
        if !hide {
            NSCursor.unhide()
        }
    }
    
    final class Coordinator: NSObject, VLCMediaPlayerDelegate, VLCMediaDelegate {
        var control: VideoView
        var volumeObserver: NSKeyValueObservation?
        var response: TrackingAreaResponse?
        let timer: WaitTimer
        private var stateObserver: NSKeyValueObservation? = nil
        
        init(_ control: VideoView) {
            self.control = control
            timer = .init(timeOut: .seconds(3)) {
                DispatchQueue.main.async {
                    control.hideTitleAndVCV(true)
                    NSCursor.hide()
                }
            }
            super.init()
            volumeObserver = control.player.observe(\.audio.volume, options: [.initial, .new]) { player, _ in
                DispatchQueue.main.async {
                    control.volumeValue = Float(player.audio.volume)
                }
            }
            
            var state = VLCMediaPlayerState.opening
            stateObserver = control.player.observe(\.state, options: [.initial, .new, .old]) { p, c in
                
                guard p.state != state else { return }
                state = p.state
                let str = VLCMediaPlayerStateToString(state)
                
                switch state {
                case .opening:
                    print(#function, "opening")
                    let videoSize = control.player.videoSize
                    control.videoSize = videoSize
                    self.updateWindowFrame()
                    self.initTrackingArea()
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
                DispatchQueue.main.async {
                    control.isPlaying = control.player.isPlaying
                    control.volumeValue = Float(control.player.audio.volume)
                }
            }
        }
        
        func mediaPlayerTimeChanged(_ aNotification: Notification!) {
            control.leftTime = control.player.time.stringValue
            control.rightTime = control.player.remainingTime.stringValue
            control.position = control.player.position
        }
        
        func mediaPlayerTitleChanged(_ aNotification: Notification!) {
            print(#function, control.player.titleDescriptions)
        }
        
        func mediaPlayerChapterChanged(_ aNotification: Notification!) {
            print(#function)
            
        }
        
// MARK: - Functions
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
        
        func initTrackingArea() {
            response = .init { type in
                let window = self.control.window
                let isFullScreen = window.styleMask.contains(.fullScreen)
                guard !window.inLiveResize,
                    !self.control.vcvIsDragging else { return }
                
                switch type {
                case .mouseEntered where isFullScreen:
                    self.control.hideTitleAndVCV(false)
                case .mouseExited where isFullScreen:
                    self.control.hideTitleAndVCV(true, onlyVCV: true)
                    self.timer.stop()
                case .mouseEntered:
                    self.control.hideTitleAndVCV(false)
                case .mouseExited:
                    self.control.hideTitleAndVCV(true)
                    self.timer.stop()
                case .mouseMoved(let event):
                    if self.control.hideVCV {
                        self.control.hideTitleAndVCV(false)
                    }
                    
                    let mouseOnVCV = !window.isMovableByWindowBackground
                    let v = window.titleView()
                    let location = event.locationInWindow
                    let mouseOnTitleBar = location.y <= window.frame.height
                        && location.y >= (window.frame.height - (v?.frame.height ?? 0))
                    
                    if mouseOnVCV || mouseOnTitleBar {
                        self.timer.stop()
                    } else {
                        self.timer.run()
                    }
                }
            }
            
            let trackingArea = NSTrackingArea(rect: control.videoView.frame, options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect], owner: response)
            control.videoView.trackingAreas.forEach {
                control.videoView.removeTrackingArea($0)
            }
            control.videoView.addTrackingArea(trackingArea)
        }
    }
    
    final class TrackingAreaResponse: NSResponder {
        
        enum ActionsType {
            case mouseEntered(event: NSEvent),
            mouseExited(event: NSEvent),
            mouseMoved(event: NSEvent)
        }
        
        init(_ actions: @escaping ((_ type: ActionsType) -> Void)) {
            self.actions = actions
            super.init()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        var actions: ((_ type: ActionsType) -> Void)

        override func mouseEntered(with event: NSEvent) {
            actions(.mouseEntered(event: event))
        }
        
        override func mouseMoved(with event: NSEvent) {
            actions(.mouseMoved(event: event))
        }
        
        override func mouseExited(with event: NSEvent) {
            actions(.mouseExited(event: event))
        }
    }
}

class MovableVideoView: VLCVideoView {
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
}
