//
//  AppDelegate.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/20.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        
        let mediaOpenPanel = Utils.shared.mediaOpenPanel
        
        let re = mediaOpenPanel.runModal()
        if re == .OK, let u = mediaOpenPanel.url {
            newPlayerWindow(u)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func newPlayerWindow(_ url: URL) {
        let windowSize = CGSize(width: 480, height: 270)
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        let contentView = ContentView(window: window, url: url)
        window.center()
        window.minSize = windowSize
//        window.backgroundColor = .black
        window.isMovableByWindowBackground = true
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }
}

extension NSWindow {
    func hideTitlebar(_ hide: Bool) {
        standardWindowButton(.closeButton)?.superview?.superview?.isHidden = hide
    }
}
