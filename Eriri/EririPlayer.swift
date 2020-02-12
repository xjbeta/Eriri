//
//  EririPlayer.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/29.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import SwiftUI

class PlayerInfo: ObservableObject, Identifiable {
    let id = UUID()
    @Published var windowSize: CGSize = .zero
    
    @Published var state: VLCMediaPlayerState = .opening
    @Published var position: Float = 0
    @Published var leftTime: String = "--:--"
    @Published var rightTime: String = "--:--"
    @Published var volume: Float = 0
    @Published var videoSize: CGSize = .zero
    
    @Published var vcvIsDragging = false
    @Published var hideVCV = false
}

class EririPlayer: NSObject {
    let window = NSWindow()
    let player = VLCMediaPlayer()
    let playerInfo = PlayerInfo()
    var response: TrackingAreaResponse?
    var timer: WaitTimer?
    private var videoSizeInited = false
    
    init(_ url: URL) {
        super.init()
        let windowMinSize = CGSize(width: 480, height: 270)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        player.setMedia(url.absoluteString)
        player.delegate = self
        
        let contentView = ContentView(window: window, player: player, playerInfo: playerInfo)
        
        window.minSize = windowMinSize
        window.isMovableByWindowBackground = true
        window.contentView = NSHostingView(rootView: contentView)
        window.setTitleWithRepresentedFilename(url.path)
        window.delegate = self
        
        timer = .init(timeOut: .seconds(3)) {
            DispatchQueue.main.async {
                self.hideTitleAndVCV(true)
                NSCursor.hide()
            }
        }
    }
    
    func hideTitleAndVCV(_ hide: Bool, onlyVCV: Bool = false) {
        if !onlyVCV {
            window.hideTitlebar(hide)
        }
        playerInfo.hideVCV = hide
        if !hide {
            NSCursor.unhide()
        }
    }
    
    func initWindowFrame() {
        let videoSize = player.videoSize
        guard !videoSizeInited, videoSize != .zero else {
            return
        }

        playerInfo.videoSize = videoSize
        updateWindowFrame()
        initTrackingArea()
        videoSizeInited = true
    }
    
    func updateWindowFrame() {
        let videoSize = player.videoSize
        window.contentAspectRatio = videoSize

        let p = window.frame.origin
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
        window.setFrame(rect, display: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
    
    func initTrackingArea() {
        response = .init { type in
            let window = self.window
            let isFullScreen = window.styleMask.contains(.fullScreen)
            guard !window.inLiveResize,
                !self.playerInfo.vcvIsDragging else { return }

            switch type {
            case .mouseEntered where isFullScreen:
                self.hideTitleAndVCV(false)
            case .mouseExited where isFullScreen:
                self.hideTitleAndVCV(true, onlyVCV: true)
                self.timer?.stop()
                NSCursor.unhide()
            case .mouseEntered:
                self.hideTitleAndVCV(false)
            case .mouseExited:
                self.hideTitleAndVCV(true)
                self.timer?.stop()
                NSCursor.unhide()
            case .mouseMoved(let event):
                NSCursor.unhide()
                if self.playerInfo.hideVCV {
                    self.hideTitleAndVCV(false)
                }

                let mouseOnVCV = !window.isMovableByWindowBackground
                let v = window.titleView()
                let location = event.locationInWindow
                let mouseOnTitleBar = location.y <= window.frame.height
                    && location.y >= (window.frame.height - (v?.frame.height ?? 0))

                if mouseOnVCV || mouseOnTitleBar {
                    self.timer?.stop()
                } else {
                    self.timer?.run()
                }
            }
        }
        guard let view = window.contentView else {
            return
        }
        let trackingArea = NSTrackingArea(rect: view.frame, options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect], owner: response)
        view.trackingAreas.forEach {
            view.removeTrackingArea($0)
        }
        view.addTrackingArea(trackingArea)
    }
    
    
    class TrackingAreaResponse: NSResponder {
        
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

extension EririPlayer: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        player.stop()
        timer?.stop()
        
        if let view = sender.contentView {
            view.trackingAreas.forEach {
                view.removeTrackingArea($0)
            }
        }
        player.delegate = nil
        NSCursor.unhide()
        Utils.shared.players.removeAll(where: {
            $0 == self
        })
        return true
    }

    func windowDidResize(_ notification: Notification) {
        playerInfo.windowSize = window.frame.size
    }
    
}

extension EririPlayer: VLCMediaPlayerDelegate {
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
        
        playerInfo.state = state
        initWindowFrame()
    }
    
    
    func mediaPlayerTimeChanged(_ time: VLCTime) {
        playerInfo.leftTime = time.stringValue()
    }
    
    func mediaPlayerLengthChanged(_ time: VLCTime) {
        playerInfo.rightTime = time.stringValue()
    }
    
    func mediaPlayerPositionChanged(_ value: Float) {
        playerInfo.position = value
    }
    
    func mediaPlayerAudioVolume(_ value: Int) {
        playerInfo.volume = Float(value)
    }
}
