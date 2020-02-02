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
        
        VStack(alignment: .center, spacing: 8) {
            // Top Items
            
            HStack {
                // Leading Items
                HStack(spacing: 5) {
                    Button(action: {
                        self.player.audio.volume = 0
                    }) {
                        Image(nsImage: NSImage(named: .init("NSAudioOutputVolumeLowTemplate"))!)
                    }.buttonStyle(ImageButtonStyle())
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
                    }.buttonStyle(ImageButtonStyle())
                        .frame(width: 21)
                }
                
                // Center Items
                HStack(alignment: .center, spacing: 30) {
                    Button(action: {
                        print("Previous")
                    }) {
                        Image(nsImage: NSImage(named: .init("NSSkipBackTemplate"))!)
                    }.buttonStyle(ImageButtonStyle())
                        .foregroundColor(Color.green)
                    
                    Button(action: {
                        self.player.togglePlay()
                    }) {
                        Image.init(isPlaying ? "PauseTemplate" : "PlayTemplate")
                            .resizable()
                            .scaledToFit()
                    }.buttonStyle(ImageButtonStyle())
                        .frame(width: 26, height: 24, alignment: .center)
                    
                    Button(action: {
                        print("Next")
                    }) {
                        Image(nsImage: NSImage(named: .init("NSSkipAheadTemplate"))!)
                    }.buttonStyle(ImageButtonStyle())
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
                    }.buttonStyle(ImageButtonStyle())
                }
            }
            
            // Buttom Items
            HStack(spacing: 12) {
                Text(leftTime)
                    .font(Font.system(size: 12).monospacedDigit())
                    .foregroundColor(Color.white.opacity(0.8))
                PlayerSliderView(value: $sliderPosition) {
                    let p = self.player
                    if p.isSeekable {
                        p.position = $0
                    }
                }
                Text(rightTime)
                    .font(Font.system(size: 12).monospacedDigit())
                    .foregroundColor(Color.white.opacity(0.8))
                    .onTapGesture {
                        
                        
                }
            }
        }.padding(.all, 14)
            .background(VisualEffectView(
                material: .hudWindow,
                blendingMode: .withinWindow))
            .frame(width: size.width, height: size.height)
            .cornerRadius(4)
    }
    
    struct ImageButtonStyle: ButtonStyle {
        func makeBody(configuration: Self.Configuration) -> some View {
            configuration.label
                .foregroundColor(Color.white)
                .opacity(configuration.isPressed ? 0.9 : 0.75)
        }
    }
}
