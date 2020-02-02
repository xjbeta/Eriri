//
//  VideoControlView.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/21.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import SwiftUI
import VLCKit

struct VideoControlView: View {
    @Binding var isPlaying: Bool
    @Binding var leftTime: String
    @Binding var rightTime: String
    @Binding var sliderPosition: Float
    @Binding var volumeValue: Float
    
    let player: VLCMediaPlayer
    let window: NSWindow
    
    let size = CGSize(width: 440, height: 75)
    let minSize = CGSize(width: 368, height: 75)
    
    var body: some View {
        
        VStack(spacing: 1) {
            // Top Items
            
            HStack {
                // Leading Items
                HStack(spacing: 5) {
                    Button(action: {
                        self.player.audio.volume = 0
                    }) {
                        Image(nsImage: NSImage(named: .init("NSAudioOutputVolumeLowTemplate"))!)
                    }.buttonStyle(BorderlessButtonStyle())
                        .frame(width: 21)
                    
                    Slider(value: $volumeValue, in: 0...100) {
                        if $0 {
                            self.player.audio.volume = Int32(self.volumeValue)
                        }
                    }
                    .controlSize(.small)
                    .frame(width: 53)
                    .padding(.leading, -8)
                    
                    
                    Button(action: {
                        self.player.audio.volume = 100
                    }) {
                        Image(nsImage: NSImage(named: .init("NSAudioOutputVolumeHighTemplate"))!)
                    }.buttonStyle(BorderlessButtonStyle())
                        .frame(width: 21)
                }
                
                // Center Items
                HStack(alignment: .center, spacing: 18) {
                    Button(action: {
                        print("Previous")
                    }) {
                        Image(nsImage: NSImage(named: .init("NSRewindTemplate"))!)
                    }.buttonStyle(BorderlessButtonStyle())
                        .foregroundColor(Color.green)
                    
                    Button(action: {
                        self.player.togglePlay()
                    }) {
                        Image(nsImage: NSImage(named: isPlaying ? .init("NSPauseTemplate") : .init("NSPlayTemplate"))!)
                            .resizable()
                            .scaledToFill()
                        
                    }.buttonStyle(BorderlessButtonStyle())
                        .frame(width: 50, alignment: .center)
                    
                    Button(action: {
                        print("Next")
                    }) {
                        Image(nsImage: NSImage(named: .init("NSFastForwardTemplate"))!)
                    }.buttonStyle(BorderlessButtonStyle())
                }
                .padding(.leading, 36)
                
                
                Spacer()
                // Trailing Items
                HStack(spacing: 5) {
                    Button(action: {
                        print("EnterFullScreen")
                        self.window.toggleFullScreen(self)
                    }) {
                        Image(nsImage: NSImage(named: .init("NSTitlebarEnterFullScreenTemplate"))!)
                    }.buttonStyle(BorderlessButtonStyle())
                }
            }.padding(.top, 2)
            
            // Buttom Items
            HStack {
                Text(leftTime)
                    .font(Font.system(size: 11).monospacedDigit())
                    .foregroundColor(.secondary)
                PlayerSliderView(value: $sliderPosition) {
                    let p = self.player
                    if p.isSeekable {
                        p.position = $0
                    }
                }
                Text(rightTime)
                    .font(Font.system(size: 11).monospacedDigit())
                    .foregroundColor(.secondary)
            }
        }.padding(.all, 14)
            .background(VisualEffectView(
                material: .fullScreenUI,
                blendingMode: .withinWindow))
            .frame(width: size.width, height: size.height)
            .cornerRadius(4)
    }
}
