//
//  Utils.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/27.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import SwiftUI
import VLCKit

class Utils: NSObject {
    static let shared = Utils()

    fileprivate override init() {
    }
    
    let subtitleTypes = ["cdg", "idx", "srt", "sub", "utf", "ass", "ssa", "aqt", "jss", "psb", "rt", "smi", "txt", "smil", "stl", "usf", "dks", "pjs", "mpl2", "mks", "vtt", "ttml", "dfxp"]
    let videoTypes = ["ts", "webm", "ogg", "ogm", "mp4", "mov", "ps", "mpjpeg", "wav", "flv", "mpeg1", "mkv", "raw", "avi", "asf", "wmv"]
    
    lazy var mediaOpenPanel: NSOpenPanel = {
        let p = NSOpenPanel()
        p.canChooseFiles = true
        p.canChooseDirectories = false
        p.canDownloadUbiquitousContents = false
        p.canResolveUbiquitousConflicts = false
        p.allowedFileTypes = videoTypes
        return p
    }()
    
    let subtitleOpenPanel = NSOpenPanel()
    
    let vlcInfos = VLCInfomations()
    lazy var infoPanel: NSPanel = {
        let p = NSPanel()
        p.delegate = self
        p.styleMask = [.titled, .closable,  .fullSizeContentView, .hudWindow]
        p.title = "Media Infomation"
        let contentView = InfoContentView(infos: vlcInfos)
        p.contentView = InfoHostingView(rootView: contentView)
        p.isMovableByWindowBackground = true
        p.level = .normal + 1
        return p
    }()
    
    var players = [EririPlayer]()
    
    func newPlayerWindow(_ url: URL) {
        let p = EririPlayer(url)
        players.append(p)
    }
}

extension Utils: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let w = notification.object as? NSWindow else { return }
        if w == infoPanel {
            vlcInfos.stop()
        }
    }
}

class InfoHostingView: NSHostingView<InfoContentView> {
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
}
