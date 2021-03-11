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
        
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(self.handleURLEvent(event:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL))
        
        NSApp.appearance = NSAppearance(named: .darkAqua)
        VLCLibrary.shared.enableLogging(true, level: .debug)
//        showMediaOpenPanel()
        let u = URL(fileURLWithPath: "/Users/xjbeta/Movies/Shelter.mkv")
        Utils.shared.newPlayerWindow(u)
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
    
    // MARK: - URL Scheme

    @objc func handleURLEvent(event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let url = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue else { return }
        print("URL event: \(url)")
        
        let utils = Utils.shared
        
        guard let eririUS = EririURLScheme(url),
              let u = URL(string: eririUS.url) else { return }
        
        utils.newPlayerWindow(u,
                              vlcOptions: eririUS.vlcOptions)
    }
    
    
}


struct EririURLScheme {
    let rawUrl: String
    let url: String
    let uuid: String
    let enableDanmaku: Bool
    
    let vlcOptions: [(name: String, value: String)]
    let eririOptions: [(name: String, value: String)]
    
    init?(_ url: String) {
        guard let parsed = URLComponents(string: url) else {
            print("Init URLComponents Failed.")
            return nil
        }
        
        rawUrl = url
        
        if parsed.scheme != "eriri" {
            vlcOptions = []
            eririOptions = []
            uuid = ""
            self.url = ""
            enableDanmaku = false
            return
        }
        
        switch parsed.host {
        case "open", "weblink":
            
            
            
            return nil
        case "iina-plus.base64":
            guard let query = parsed.query,
                  let queryData = Data(base64Encoded: query),
                  let dicStr = String(data: queryData, encoding: .utf8) else { return nil }
            
            var eOptions = [(name: String, value: String)]()
            var vOptions = [(name: String, value: String)]()
            
            let queries = dicStr.split(separator: "👻").map(String.init).compactMap { str -> (name: String, value: String)? in
              let kv = str.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true).map(String.init)
              guard kv.count > 0 else { return nil }
              let name = kv[0]
              let value = kv.count == 2 ? kv[1] : ""
              return (name, value)
            }
            
            var uuid = ""
            var enableDanmaku = false
            var url = ""
            
            queries.forEach {
                switch $0.name {
                case _ where $0.name.starts(with: "vlc_"):
                    let n = String($0.name.dropFirst(4))
                    vOptions.append((n, $0.value))
                case "uuid":
                    uuid = $0.value
                case "danmaku":
                    enableDanmaku = true
                case "url":
                    url = $0.value
                default:
                    eOptions.append(($0.name, $0.value))
                }
            }
            
            self.uuid = uuid
            self.enableDanmaku = enableDanmaku
            
            guard !url.isEmpty else {
              print("Cannot find parameter \"url\", stopped")
              return nil
            }
            
            self.url = url
            eririOptions = eOptions
            vlcOptions = vOptions

        default:
            return nil
        }
    }
}
