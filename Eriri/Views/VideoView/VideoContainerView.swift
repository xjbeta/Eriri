//
//  VideoContainerView.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/23.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import SwiftUI

struct VideoContainerView: View {
    @State private var vcvCurrentPosition: CGPoint = .zero
    @State private var vcvNewPosition: CGPoint = .zero
    
    let window: NSWindow
    var player: VLCMediaPlayer
    @ObservedObject var playerInfo: PlayerInfo
    
    @State private var positionInited: Bool = false
    
    var body: some View {
        videoView
            .overlay(
                self.videoControlView(playerInfo.windowSize)
                    .opacity(self.playerInfo.hideVCV ? 0 : 1))
            .frame(minWidth: limitWindowSize(playerInfo.videoSize).width,
                   minHeight: limitWindowSize(playerInfo.videoSize).height)
    }
    
    var videoView: some View {
        VideoView(player: player)
    }
    
    func videoControlView(_ windowSize: CGSize) -> some View {
        let dragGesture = DragGesture()
            .onChanged { value in
                self.playerInfo.vcvIsDragging = true
                let x = value.translation.width + self.vcvNewPosition.x
                let y = value.translation.height + self.vcvNewPosition.y
                
                let newP = self.vcvLimitPosition(windowSize, .init(x: x, y: y))
                
                self.vcvCurrentPosition = newP
        }.onEnded { _ in
            self.playerInfo.vcvIsDragging = false
            self.vcvNewPosition = self.vcvCurrentPosition
            
            // Mouse outside window
            if NSWindow.windowNumber(at: NSEvent.mouseLocation, belowWindowWithWindowNumber: 0) != self.window.windowNumber {
                self.window.hideTitlebar(true)
                self.playerInfo.hideVCV = true
            }
        }
        
        DispatchQueue.main.async {
            if self.positionInited {
                self.vcvCurrentPosition = self.vcvLimitPosition(windowSize, self.vcvCurrentPosition)
            } else if windowSize != .zero {
                let p = CGPoint(x: 0, y: windowSize.height / 4)
                let np = self.vcvLimitPosition(windowSize, p)
                self.positionInited = true
                self.vcvCurrentPosition = np
                self.vcvNewPosition = np
            }
        }
        return VideoControlView(window: window,
                                player: player,
                                playerInfo: playerInfo)
            .onHover {
                self.window.isMovableByWindowBackground = !$0
            }
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
}
