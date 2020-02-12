//
//  VideoControlView.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/21.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import SwiftUI

struct VideoControlView: View {
    
    let window: NSWindow
    let player: VLCMediaPlayer
    @ObservedObject var playerInfo: PlayerInfo
    
    let size = CGSize(width: 440, height: 75)
    let minSize = CGSize(width: 368, height: 75)
    
    var leadingItems: some View {
        HStack(spacing: 5) {
            Button(action: {
                self.player.volume = self.player.volumeMIN
            }) {
                Image(nsImage: NSImage(named: .init("NSAudioOutputVolumeLowTemplate"))!)
            }.buttonStyle(ImageButtonStyle())
                .frame(width: 21)
            
            Slider(value: $playerInfo.volume, in: 0...100) {
                if $0 {
                    self.player.volume = Int(self.playerInfo.volume)
                }
            }
            .controlSize(.small)
            .frame(width: 53)
            .padding(.leading, -8)
            
            
            Button(action: {
                self.player.volume = self.player.volumeMAX
            }) {
                Image(nsImage: NSImage(named: .init("NSAudioOutputVolumeHighTemplate"))!)
            }.buttonStyle(ImageButtonStyle())
                .frame(width: 21)
        }
    }
    
    var centerItems: some View {
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
                Image(playerInfo.state == .playing ? "PauseTemplate" : "PlayTemplate")
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
    }
    
    var trailingItems: some View {
        HStack(spacing: 5) {
            Button(action: {
                print("EnterFullScreen")
                self.window.toggleFullScreen(self)
            }) {
                Image(nsImage: NSImage(named: .init("NSTitlebarEnterFullScreenTemplate"))!)
            }.buttonStyle(ImageButtonStyle())
        }
    }
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 8) {
            // Top Items
            HStack {
                leadingItems
                Spacer()
                trailingItems
            }.overlay(centerItems)
            
            // Buttom Items
            HStack(spacing: 12) {
                Text(playerInfo.leftTime)
                    .font(Font.system(size: 12).monospacedDigit())
                    .foregroundColor(Color.white.opacity(0.8))
                PlayerSliderView(value: $playerInfo.position) {
                    self.player.position = $0
                }
                Text(playerInfo.rightTime)
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
