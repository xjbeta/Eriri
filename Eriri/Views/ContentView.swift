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
    let url: URL
    var body: some View {
        VideoContainerView(url: url, window: window)
            .padding(.top, -22)
    }
}
