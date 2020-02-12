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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        VLCLibrary.shared.enableLogging(true, level: .debug)
        showMediaOpenPanel()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func showMediaOpenPanel() {
        let utils = Utils.shared
        let mediaOpenPanel = utils.mediaOpenPanel
        let re = mediaOpenPanel.runModal()
        if re == .OK, let u = mediaOpenPanel.url {
            utils.newPlayerWindow(u)
        } else if re == .cancel {
            
        }
    }
    
}
