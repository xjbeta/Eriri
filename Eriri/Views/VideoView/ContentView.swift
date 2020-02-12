//
//  ContentView.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/20.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    let window: NSWindow
    let player: VLCMediaPlayer
    @ObservedObject var playerInfo: PlayerInfo
    
    var body: some View {
        VideoContainerView(window: window, player: player, playerInfo: playerInfo)
            .padding(.top, -22)
    }
}
