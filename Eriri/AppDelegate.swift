//
//  AppDelegate.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/20.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import SwiftUI
import VLCKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var playerContainers = [(window: NSWindow,
                             player: VLCMediaPlayer)]()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        showMediaOpenPanel()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func showMediaOpenPanel() {
        let mediaOpenPanel = Utils.shared.mediaOpenPanel
        let re = mediaOpenPanel.runModal()
        if re == .OK, let u = mediaOpenPanel.url {
            newPlayerWindow(u)
        }
    }
    
    func newPlayerWindow(_ url: URL) {
        let windowSize = CGSize(width: 480, height: 270)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        
        let player = VLCMediaPlayer()
        player.media = .init(url: url)
        
        let contentView = ContentView(window: window, player: player)
        
        window.minSize = windowSize
        window.isMovableByWindowBackground = true
        window.contentView = NSHostingView(rootView: contentView)
        window.setTitleWithRepresentedFilename(url.path)
        window.delegate = self
        playerContainers.append((window, player))
    }
}
    }
}

extension NSWindow {
    func hideTitlebar(_ hide: Bool) {
        standardWindowButton(.closeButton)?.superview?.superview?.isHidden = hide
    }
}
