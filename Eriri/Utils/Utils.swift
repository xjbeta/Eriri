//
//  Utils.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/27.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa

class Utils: NSObject {
    static let shared = Utils()

    fileprivate override init() {
        mediaOpenPanel.canChooseFiles = true
        mediaOpenPanel.canChooseDirectories = false
        mediaOpenPanel.canDownloadUbiquitousContents = false
        mediaOpenPanel.canResolveUbiquitousConflicts = false
        mediaOpenPanel.allowedFileTypes = videoTypes
        
        
    }
    
    let subtitleTypes = ["cdg", "idx", "srt", "sub", "utf", "ass", "ssa", "aqt", "jss", "psb", "rt", "smi", "txt", "smil", "stl", "usf", "dks", "pjs", "mpl2", "mks", "vtt", "ttml", "dfxp"]
    let videoTypes = ["ts", "webm", "ogg", "ogm", "mp4", "mov", "ps", "mpjpeg", "wav", "flv", "mpeg1", "mkv", "raw", "avi", "asf", "wmv"]
    
    let mediaOpenPanel = NSOpenPanel()
    let subtitleOpenPanel = NSOpenPanel()
    
    
}
