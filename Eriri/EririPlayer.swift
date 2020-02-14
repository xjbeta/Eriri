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
    let date = Date()
    @Published var state: VLCMediaPlayerState = .opening {
        didSet {
            print("state", date.timeIntervalSinceNow,state)
        }
    }
    @Published var position: Float = 0
    @Published var leftTime: String = "--:--"
    @Published var rightTime: String = "--:--"
    @Published var volume: Float = 0
    @Published var videoSize: CGSize = .zero
    
    @Published var vcvIsDragging = false
    @Published var hideVCV = false
    @Published var isFullScreen = false
    @Published var playerSliderIsSeeking = false
    @Published var playerSliderExpectedValue: Float = -1
    @Published var playerBuffingValue: Float = 100
    
    
}

class EririPlayer: NSObject {
    let window = NSWindow()
    let player = VLCMediaPlayer()
    let playerInfo = PlayerInfo()
    private var videoSizeInited = false
    
    var responses = [TrackingAreaResponse]()
    var timer: WaitTimer?
    
    private var positionIgnoreLimit = 0
    
    enum ActionsType {
        case mouseEntered(event: NSEvent),
        mouseExited(event: NSEvent),
        mouseMoved(event: NSEvent)
    }
    
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
                NSCursor.setHiddenUntilMouseMoves(true)
            }
        }
    }
    
    func hideTitleAndVCV(_ hide: Bool, onlyVCV: Bool = false) {
        if !onlyVCV {
            window.hideTitlebar(hide)
        }
        playerInfo.hideVCV = hide
    }
    
    func initWindowFrame() {
        let videoSize = player.videoSize
        guard !videoSizeInited, videoSize != .zero else {
            return
        }

        playerInfo.videoSize = videoSize
        updateWindowFrame()
        if let view = window.contentView {
            initTrackingArea(view, isFullScreen: false)
        }
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
    
    func initTrackingArea(_ view: NSView, isFullScreen: Bool) {
        let response = TrackingAreaResponse {
            self.handleMouseActions($0)
        }
        responses.append(response)
        let options: NSTrackingArea.Options = isFullScreen ?
                [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect] :
                [.mouseEnteredAndExited, .mouseMoved, .activeAlways]
        
        let trackingArea = NSTrackingArea(rect: view.frame, options: options, owner: response)
        deinitTrackingArea(view)

        view.addTrackingArea(trackingArea)
    }
    
    func deinitTrackingArea(_ view: NSView) {
        view.trackingAreas.forEach {
            view.removeTrackingArea($0)
        }
    }
    
    func handleMouseActions(_ type: ActionsType) {
        let isFullScreen = window.styleMask.contains(.fullScreen)
        
        guard !window.inLiveResize,
            !playerInfo.vcvIsDragging else { return }
        
        switch type {
        case .mouseEntered:
            hideTitleAndVCV(false)
        case .mouseExited:
            hideTitleAndVCV(true, onlyVCV: isFullScreen)
            timer?.stop()
        case .mouseMoved(let event):
            if playerInfo.hideVCV {
                hideTitleAndVCV(false)
            }

            let mouseOnVCV = !window.isMovableByWindowBackground
            let mouseOnTitleBar = event.isIn(views: [window.titleView()])

            if mouseOnVCV || mouseOnTitleBar {
                timer?.stop()
            } else {
                timer?.run()
            }
        }
    }
    
    class TrackingAreaResponse: NSResponder {
        
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
        Utils.shared.players.removeAll(where: {
            $0 == self
        })
        return true
    }

    func windowDidResize(_ notification: Notification) {
        playerInfo.windowSize = window.frame.size
    }
    
    func windowWillExitFullScreen(_ notification: Notification) {
        playerInfo.isFullScreen = false
        guard let v = window.contentView else { return }
        deinitTrackingArea(v)
        initTrackingArea(v, isFullScreen: false)
        
    }
    
    func windowWillEnterFullScreen(_ notification: Notification) {
        playerInfo.isFullScreen = true
        guard let v = window.contentView else { return }
        deinitTrackingArea(v)
        initTrackingArea(v, isFullScreen: true)
    }
    
    
}

extension EririPlayer: VLCMediaPlayerDelegate {
    func mediaPlayerBuffing(_ newCache: Float) {
        playerInfo.playerBuffingValue = newCache
    }
    
    func mediaPlayerStateChanged(_ state: VLCMediaPlayerState) {
        switch state {
        case .opening:
            break
        case .stopped:
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
        guard !playerInfo.playerSliderIsSeeking, playerInfo.playerBuffingValue == 100 else { return }
        
        let expectedValue = playerInfo.playerSliderExpectedValue
        var v = value
        func resetExpected() {
            playerInfo.playerSliderExpectedValue = -1
            positionIgnoreLimit = 0
        }
        
        if expectedValue != -1 {
            if v > expectedValue + 0.02
                || v < expectedValue - 0.02 {
                if positionIgnoreLimit <= 3 {
                    v = expectedValue
                    positionIgnoreLimit += 1
                } else {
                   resetExpected()
                }
            } else {
                resetExpected()
            }
        }
        
        playerInfo.position = v
    }
    
    func mediaPlayerAudioVolume(_ value: Int) {
        playerInfo.volume = Float(value)
    }
}
