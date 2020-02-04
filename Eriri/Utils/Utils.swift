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
    let vlcDialogProvider: VLCDialogProvider?
    
    fileprivate override init() {
        let l = VLCLibrary.shared()
        vlcDialogProvider = VLCDialogProvider(library: l, customUI: true)
        super.init()
        l.debugLoggingLevel = 2
        l.debugLogging = true
        VLCLibrary.shared().debugLoggingTarget = self
        vlcDialogProvider?.customRenderer = self
    }
    
    let supportedFileExtensions = ["3g2", "3gp", "3gp2", "3gpp", "amv", "asf", "avi", "bik", "bin", "crf", "divx", "drc", "dv", "evo", "f4v", "flv", "gvi", "gxf", "iso", "m1v", "m2v", "m2t", "m2ts", "m4v", "mkv", "mov", "mp2", "mp2v", "mp4", "mp4v", "mpe", "mpeg", "mpeg1", "mpeg2", "mpeg4", "mpg", "mpv2", "mts", "mtv", "mxf", "mxg", "nsv", "nuv", "ogg", "ogm", "ogv", "ogx", "ps", "rec", "rm", "rmvb", "rpl", "thp", "tod", "ts", "tts", "txd", "vlc", "vob", "vro", "webm", "wm", "wmv", "wtv", "xesc"]
    
    let supportedSubtitleFileExtensions = ["cdg", "idx", "srt", "sub", "utf", "ass", "ssa", "aqt", "jss", "psb", "rt", "smi", "txt", "smil", "stl", "usf", "dks", "pjs", "mpl2", "mks", "vtt", "ttml", "dfxp"]
    
    let supportedAudioFileExtensions = ["3ga", "669", "a52", "aac", "ac3", "adt", "adts", "aif", "aifc", "aiff", "amb", "amr", "aob", "ape", "au", "awb", "caf", "dts", "flac", "it", "kar", "m4a", "m4b", "m4p", "m5p", "mid", "mka", "mlp", "mod", "mpa", "mp1", "mp2", "mp3", "mpc", "mpga", "mus", "oga", "ogg", "oma", "opus", "qcp", "ra", "rmi", "s3m", "sid", "spx", "tak", "thd", "tta", "voc", "vqf", "w64", "wav", "wma", "wv", "xa", "xm"]
    
    let supportedPlaylistFileExtensions = ["asx", "b4s", "cue", "ifo", "m3u", "m3u8", "pls", "ram", "rar", "sdp", "vlc", "xspf", "wax", "wvx", "zip", "conf"]
    
    let supportedProtocolSchemes = ["rtsp", "mms", "mmsh", "udp", "rtp", "rtmp", "sftp", "ftp", "smb"]
    
    lazy var mediaOpenPanel: NSOpenPanel = {
        let p = NSOpenPanel()
        p.canChooseFiles = true
        p.canChooseDirectories = false
        p.canDownloadUbiquitousContents = false
        p.canResolveUbiquitousConflicts = false
        p.allowedFileTypes = supportedFileExtensions
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
