//
//  PlayerSliderView.swift
//  Eriri
//
//  Created by xjbeta on 2020/2/1.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import SwiftUI

struct PlayerSliderView: View {
    @Binding var value: Float
    var onChanged: ((Float) -> Void)
        
    @State private var isSeeking: Bool = false
    @State private var dValue: Float = 0
    @State private var ignoreUpdateCount = -1
    
    enum BarType {
        case played, cached, other
    }
    private let barHeight: CGFloat = 3
    private let barPlayedColor = Color.white.opacity(0.5)
    private let barCachedColor = Color.white.opacity(0.275)
    private let barOtherColor = Color.white.opacity(0.2)
    
    private let knobSize = NSSize(width: 3, height: 15)
    private let knobColor = Color.white.opacity(0.6)
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                HStack(spacing: self.knobSize.width + 2) {
                    // Played
                    Rectangle()
                        .frame(width: self.barWidth(.played, isDragging: self.isSeeking, proxy: proxy, value: self.value, dValue: self.dValue))
                        .foregroundColor(self.barPlayedColor)
                    // Cached
                    
                    // Other
                    Rectangle()
                        .frame(width: self.barWidth(.other, isDragging: self.isSeeking, proxy: proxy, value: self.value, dValue: self.dValue))
                        .foregroundColor(self.barOtherColor)
                }
                .frame(width: proxy.size.width,
                       height: self.barHeight)
                    .cornerRadius(self.barHeight / 2)
                Rectangle()
                    .frame(width: self.knobSize.width,
                           height: self.knobSize.height)
                    .cornerRadius(1)
                    .offset(self.knobOffset(isDragging: self.isSeeking, proxy: proxy, value: self.value, dValue: self.dValue))
                    .foregroundColor(self.knobColor)
            }
            .frame(width: proxy.size.width, height: self.knobSize.height + 4)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    self.isSeeking = true
                    self.ignoreUpdateCount = -1
                    var f = value.location.x / proxy.size.width
                    switch f {
                    case _ where f < 0:
                        f = 0
                    case _ where f > 1:
                        f = 1
                    default:
                        break
                    }
                    let v = Float(f)
                    self.dValue = v
                    self.onChanged(v)
            }.onEnded { _ in
                self.ignoreUpdateCount = 0
                let v = self.dValue
                self.onChanged(v)
            })
        }
    }
    
    func barWidth(_ type: BarType, isDragging: Bool, proxy: GeometryProxy, value: Float, dValue: Float) -> CGFloat {
        let knobWidth = self.knobSize.width
        let v = isSeeking ? dValue : value
        
        DispatchQueue.main.async {
            // Prevent the "value" from being updated to another position
            guard self.isSeeking,
                self.ignoreUpdateCount >= 0 else { return }
            if self.ignoreUpdateCount > 5 {
                self.isSeeking = false
                self.ignoreUpdateCount = -1
            } else {
                self.ignoreUpdateCount += 1
            }
        }
        
        switch type {
        case .played:
            return proxy.size.width * CGFloat(v) - (knobWidth / 2 + 1)
        case .other:
            return proxy.size.width * CGFloat(1 - v) - (knobWidth / 2 + 1)
        default:
            break
        }
        return 0
    }
    
    func knobOffset(isDragging: Bool, proxy: GeometryProxy, value: Float, dValue: Float) -> CGSize {
        let width = proxy.size.width
        
        let v = isSeeking ? dValue : value
        var w = -width/2
        
        w += width * CGFloat(v)
        return .init(width: w, height: 0)
    }
}

