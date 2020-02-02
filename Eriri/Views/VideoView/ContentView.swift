//
//  ContentView.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/20.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import SwiftUI
import VLCKit

struct ContentView: View {
    let window: NSWindow
    let player: VLCMediaPlayer
    @ObservedObject var windowSize: WindowSize
    
    var body: some View {
        VideoContainerView(window: window, player: player, windowSize: windowSize)
            .padding(.top, -22)
    }
}
