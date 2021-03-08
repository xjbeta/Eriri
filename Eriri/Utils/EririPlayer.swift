//
//  EririPlayer.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/29.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import SwiftUI
import MetalKit

class PlayerInfo: ObservableObject, Identifiable {
    let id = UUID()
    
    var time: Int64 = 0
    
    @Published var windowSize: CGSize = .zero
    @Published var state: VLCMediaPlayerState = .opening
    @Published var position: Float = 0
    @Published var leftTime: String = "--:--"
    @Published var rightTime: String = "--:--"
    @Published var rightTimeR: String = "--:--"
    @Published var showRemainingTime: Bool = false
    @Published var volume: Float = -1
    @Published var videoSize: CGSize = .zero
    
    @Published var vcvIsDragging = false
    @Published var hideVCV = false
    @Published var isFullScreen = false
    
    @Published var playerSliderIsSeeking = false
    @Published var playerSliderExpectedValue: Float = -1
    @Published var playerBuffingValue: Float = 100
    
    @Published var hideNotification = true
    @Published var notificationT1 = ""
    @Published var notificationT2 = ""
}

class EririPlayer: NSObject {
    let window = NSWindow()
    let player = VLCMediaPlayer()
    let playerInfo = PlayerInfo()
    private var videoSizeInited = false
    
    var responses = [TrackingAreaResponse]()
    var hideVCVTimer: WaitTimer?
    var playerNotificationTimer: WaitTimer?
    
    private var positionIgnoreLimit = 0
    
    let mtkView: MTKView
//    let assRenderer: ASSRenderer

    enum ActionsType {
        case mouseEntered(event: NSEvent),
        mouseExited(event: NSEvent),
        mouseMoved(event: NSEvent)
    }
    
    init(_ url: URL) {
        mtkView = MTKView()
//        assRenderer = ASSRenderer(mtkView, "/Users/xjbeta/Downloads/test files/Shelter.ass")
        
        super.init()
        let windowMinSize = CGSize(width: 480, height: 270)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        player.setMedia(url.absoluteString)
        player.delegate = self
        
        playerInfo.volume = Float(player.volume)
        
        let contentView = VideoContentView(
            window: window,
            player: player,
            mtkView: mtkView,
            playerInfo: playerInfo)
        
        window.minSize = windowMinSize
        window.isMovableByWindowBackground = true
        window.contentView = NSHostingView(rootView: contentView)
        window.delegate = self
        window.backgroundColor = .black
        hideVCVTimer = .init(timeOut: .seconds(3)) {
            DispatchQueue.main.async {
                guard self.window.isMovableByWindowBackground else {
                    return
                }
                
                self.hideTitleAndVCV(true)
                NSCursor.setHiddenUntilMouseMoves(true)
            }
        }
        
        playerNotificationTimer = .init(timeOut: .milliseconds(1500)) {
            DispatchQueue.main.async {
                let i = self.playerInfo
                i.hideNotification = true
                i.notificationT1 = ""
                i.notificationT2 = ""
            }
        }
        

        
    }
    
    func postNotification(_ label: String,
                          _ second: String = "") {
        
        return 
        let i = self.playerInfo
        i.notificationT1 = label
        i.notificationT2 = second
        i.hideNotification = false
        playerNotificationTimer?.run()
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
        guard let view = window.contentView else { return }
        let isFullScreen = playerInfo.isFullScreen
        
        let response = TrackingAreaResponse {
            self.handleMouseActions($0)
        }
        responses.append(response)
        let options: NSTrackingArea.Options = isFullScreen ?
                [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect] :
                [.mouseEnteredAndExited, .mouseMoved, .activeAlways]
        
        let trackingArea = NSTrackingArea(rect: view.frame, options: options, owner: response)
        
        view.trackingAreas.forEach {
            view.removeTrackingArea($0)
        }

        view.addTrackingArea(trackingArea)
    }
    
    func handleMouseActions(_ type: ActionsType) {
        func updateTimer(_ event: NSEvent) {
            let mouseOnVCV = !window.isMovableByWindowBackground
            let mouseOnTitleBar = event.isIn(views: [window.titleView()])
            if mouseOnVCV || mouseOnTitleBar {
                hideVCVTimer?.stop()
            } else {
                hideVCVTimer?.run()
            }
        }
        
        let isFullScreen = window.styleMask.contains(.fullScreen)
        
        guard !window.inLiveResize,
            !playerInfo.vcvIsDragging else { return }
        
        switch type {
        case .mouseEntered(let event):
            hideTitleAndVCV(false)
            updateTimer(event)
        case .mouseExited:
            hideTitleAndVCV(true, onlyVCV: isFullScreen)
            hideVCVTimer?.stop()
        case .mouseMoved(let event):
            if playerInfo.hideVCV {
                hideTitleAndVCV(false)
            }
            updateTimer(event)
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
        hideVCVTimer?.stop()
        
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
        initTrackingArea()
    }
    
    func windowWillExitFullScreen(_ notification: Notification) {
        playerInfo.isFullScreen = false
        initTrackingArea()
    }
    
    func windowWillEnterFullScreen(_ notification: Notification) {
        playerInfo.isFullScreen = true
        initTrackingArea()
    }
    
    
}

extension EririPlayer: VLCMediaPlayerDelegate {
    func mediaPlayerAudioMuted(_ muted: Bool) {
        let s = muted ? "Muted" : "Unmuted"
        postNotification(s)
    }
    
    func mediaPlayerBuffing(_ newCache: Float) {
        playerInfo.playerBuffingValue = newCache
        
        if playerInfo.state == .paused {
            mediaPlayerTimeChanged(player.time)
            mediaPlayerPositionChanged(player.position)
        }
    }
    
    func mediaPlayerStateChanged(_ state: VLCMediaPlayerState) {
        switch state {
        case .opening:
            break
        case .stopped:
            postNotification("Stopped")
        case .ended:
            break
        case .error:
            break
        case .playing:
            postNotification("Playing")
        case .paused:
            postNotification("Paused")
            break
        case .nothingSpecial:
            break
        case .buffering:
            break
        }
        
        if playerInfo.state == .opening,
           (state == .paused || state == .playing || state == .buffering) {
            let path = player.path()
            let p = URL(string: path)?.path.removingPercentEncoding ?? ""
            window.setTitleWithRepresentedFilename(p)
        }
        
        playerInfo.state = state
        initWindowFrame()
    }
    
    
    func mediaPlayerTimeChanged(_ time: VLCTime) {
        guard time.value != playerInfo.time else { return }
        playerInfo.time = time.value
        
//        assRenderer.update(time.value)
        
        playerInfo.leftTime = time.stringValue()
        let r = VLCTime(with: player.mediaLength.value - time.value).stringValue()
        playerInfo.rightTimeR = "-\(r)"
    }
    
    func mediaPlayerLengthChanged(_ time: VLCTime) {
        playerInfo.rightTime = time.stringValue()
        let r = VLCTime(with: time.value - player.time.value).stringValue()
        playerInfo.rightTimeR = "-\(r)"
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
        if playerInfo.volume != -1 {
            postNotification("Volume: \(value)")
        }
        
        playerInfo.volume = Float(value)
    }
}
