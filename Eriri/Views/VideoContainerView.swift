//
//  VideoContainerView.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/23.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import SwiftUI
import VLCKit

struct VideoContainerView: View {
    @State private var isPlaying: Bool = false
    @State private var leftTime: String = "--:--"
    @State private var rightTime: String = "--:--"
    @State private var videoSize: CGSize = .zero
    
    @State private var sliderPosition: Float = 0
    @State private var volumePosition: Float = 0
    
    
    @State private var vcvCurrentPosition: CGPoint = .zero
    @State private var vcvNewPosition: CGPoint = .zero
    @State private var vcvIsDragging: Bool = false
    
    @State private var hoverOnWindow: Bool = false
    @State private var hideVCV: Bool = false
    
    let window: NSWindow
    var player: VLCMediaPlayer
    
    init(window: NSWindow, player: VLCMediaPlayer) {
        self.window = window
        self.player = player
    }
    
    var body: some View {
        videoView
            .overlay(
                GeometryReader { (proxy: GeometryProxy) in
                    self.videoControlView(proxy)
                }.opacity(self.hideVCV ? 0 : 1))
            .frame(minWidth: limitWindowSize(videoSize).width,
                   minHeight: limitWindowSize(videoSize).height)
            .onHover {
                self.hoverOnWindow = $0
                var hide = !$0
                if self.window.styleMask.contains(.fullScreen) ||
                    self.window.inLiveResize ||
                    self.vcvIsDragging {
                    if self.hideVCV {
                        hide = false
                    } else {
                        return
                    }
                }
                self.hideTitleAndVCV(hide)
        }
    }
    
    var videoView: some View {
        VideoView(isPlaying: $isPlaying,
                  leftTime: $leftTime,
                  rightTime: $rightTime,
                  videoSize: $videoSize,
                  position: $sliderPosition,
                  volumePosition: $volumePosition,
                  windowIsResizing: .init(get: { () -> Bool in
                    return false
                  }, set: {
                    if !$0 {
                        // Hide after window resizing
                        self.hideTitleAndVCV(true)
                    }
                  }),
                  player: player,
                  window: window)
            .gesture(DragGesture()
                .onChanged { value in
                    var o = self.window.frame.origin
                    o.x += value.translation.width
                    o.y -= value.translation.height
                    self.window.setFrameOrigin(o)
            })
    }
    
    func videoControlView(_ proxy: GeometryProxy) -> some View {
        let dragGesture = DragGesture()
            .onChanged { value in
                self.vcvIsDragging = true
                let x = value.translation.width + self.vcvNewPosition.x
                let y = value.translation.height + self.vcvNewPosition.y
                
                let newP = self.vcvLimitPosition(proxy.size, .init(x: x, y: y))
                
                self.vcvCurrentPosition = newP
        }.onEnded { _ in
            self.vcvIsDragging = false
            self.vcvNewPosition = self.vcvCurrentPosition
            if !self.hoverOnWindow {
                self.hideTitleAndVCV(true)
            }
        }
        
        DispatchQueue.main.async {
            self.vcvCurrentPosition = self.vcvLimitPosition(proxy.size, self.vcvCurrentPosition)
        }
        return VideoControlView(isPlaying: $isPlaying,
                                leftTime: $leftTime,
                                rightTime: $rightTime,
                                sliderPosition: $sliderPosition,
                                volumePosition: $volumePosition,
                                player: player,
                                window: window)
            .offset(x: vcvCurrentPosition.x,
                    y: vcvCurrentPosition.y)
            .gesture(dragGesture)
    }
    
    func limitWindowSize(_ videoSize: CGSize) -> CGSize {
        let defaultSize = CGSize(width: 480, height: 480)
        let minHeight: CGFloat = 75 + 30 + 8
        guard videoSize != .zero else {
            return defaultSize
        }
        
        let ratio = videoSize.width / videoSize.height
        switch ratio {
        case _ where ratio > 1:
            var w = defaultSize.width
            var h = w / ratio
            if h < minHeight {
                h = minHeight
                w = h * ratio
            }
            return .init(width: w, height: h)
        case _ where ratio < 1:
            let h = defaultSize.height
            let w = h * ratio
            return .init(width: w, height: h)
        default:
            break
        }
        return defaultSize
    }
    
    func vcvLimitPosition(_ bodySize: CGSize, _ position: CGPoint) -> CGPoint {
        let cSize = CGSize(width: 440, height: 75)
        
        let dragEdgeLimit: CGFloat = 8
        var x = position.x
        var y = position.y
        
        let wMax = (bodySize.width - cSize.width)/2 - dragEdgeLimit
        let hMax = (bodySize.height - cSize.height)/2 - dragEdgeLimit
        
        switch x {
        case _ where x > 0 && x > wMax:
            x = wMax
        case _ where x < 0 && x < -wMax:
            x = -wMax
        default:
            break
        }
        switch y {
        case _ where y > 0 && y > hMax:
            y = hMax
        case _ where y < 0 && y < (-hMax + 22):
            y = (-hMax + 22)
        default:
            break
        }
        
        return CGPoint(x: x, y: y)
    }
    
    func hideTitleAndVCV(_ hide: Bool) {
        hideVCV = hide
        window.hideTitlebar(hide)
    }
}
