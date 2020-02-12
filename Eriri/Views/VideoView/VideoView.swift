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
    
    func makeNSView(context: Context) -> VLCVideoView {
        player.delegate = context.coordinator
        player.videoView = videoView
        player.play()
        return videoView
    }
    
    
    func updateNSView(_ nsView: VLCVideoView, context: Context) {
        
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
    
    final class Coordinator: NSObject, VLCMediaPlayerDelegate {
        
        var control: VideoView
        var response: TrackingAreaResponse?
        let timer: WaitTimer
        
        private var shouldInit = true
        
        init(_ control: VideoView) {
            self.control = control
            timer = .init(timeOut: .seconds(3)) {
                DispatchQueue.main.async {
                    control.hideTitleAndVCV(true)
                    NSCursor.hide()
                }
            }
            super.init()
            control.player.initEventAttachs()
        }

        func mediaPlayerStateChanged(_ state: VLCMediaPlayerState) {
            switch state {
            case .opening:
                break
            case .stopped:
                break
            case .buffering:
                break
            case .ended:
                break
            case .error:
                break
            case .playing:
                 break
            case .paused:
                break
            case .esAdded:
                break
            }
            if shouldInit {
                DispatchQueue.main.async {
                    self.initWindowFrame()
                }
            }
            control.isPlaying = state == .playing
        }
        
        
        func mediaPlayerTimeChanged(_ time: VLCTime) {
            control.leftTime = time.stringValue()
        }
        
        func mediaPlayerPositionChanged(_ value: Float) {
            control.position = value
        }
        
        func mediaPlayerLengthChanged(_ time: VLCTime) {
            control.rightTime = time.stringValue()
        }
        
        func mediaPlayerAudioVolume(_ value: Int) {
            control.volumeValue = Float(value)
        }
        
// MARK: - Functions
        func initWindowFrame() {
            let videoSize = control.player.videoSize
            
            guard shouldInit, videoSize != .zero else {
                return
            }
            
            control.videoSize = videoSize
            updateWindowFrame()
            initTrackingArea()
            shouldInit = false
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
                    NSCursor.unhide()
                case .mouseEntered:
                    self.control.hideTitleAndVCV(false)
                case .mouseExited:
                    self.control.hideTitleAndVCV(true)
                    self.timer.stop()
                    NSCursor.unhide()
                case .mouseMoved(let event):
                    NSCursor.unhide()
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

class VLCVideoView: NSView {
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
}
