//
//  VLCLibrary.swift
//  Eriri
//
//  Created by xjbeta on 2020/2/9.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import Darwin

class VLCLibrary: NSObject {
    static let shared = VLCLibrary()
    var instance: OpaquePointer?
    
    private var enableLogging = false
    
    let defaultOptions = [
        //        "--play-and-pause",
        "--no-color",
        "--no-video-title-show",
        "--no-sout-keep",
        "--vout=macosx",
        "--text-renderer=freetype",
        "--extraintf=macosx_dialog_provider",
        "--audio-resampler=soxr"]
    
    
    fileprivate override init() {
        super.init()
//        let path = "/Users/xjbeta/Developer/Eriri/libvlc/plugins"
//        if setenv("VLC_PLUGIN_PATH", path, 1) != 0 {
//            print("Set plugins path error \(errno)")
//        }
        
        let options = defaultOptions
        let argv: [UnsafePointer<Int8>?] = options.map({ $0.withCString({ $0 }) })
        
        instance = libvlc_new(Int32(options.count), argv)
        
        libvlc_set_app_id(instance, "com.xjbeta.Eriri", "1.0", "foobar")
    }
    
    enum LogLevel: Int32 {
        case debug = 0
        case notice = 2
        case warning = 3
        case error = 4
    }
    
    
    func enableLogging(_ enable: Bool, level: LogLevel = .debug) {
        guard let i = instance else { return }
        enableLogging = enable
        guard enable else {
            libvlc_log_unset(i)
            return
        }

        libvlc_log_set(i, { data, level, ctx, fmt, args in
            var str: UnsafeMutablePointer<Int8>?
            if vasprintf(&str, fmt, args) == -1 {
                if str != nil {
                    free(str)
                }
            }
            guard let s = str else { return }
            let ss = String(cString: s)
            
            print("VLC LOG: \(ss)")
            
        }, Unmanaged.passUnretained(self).toOpaque())
    }
    
    func version() -> String {
        guard let v = libvlc_get_version() else {
            return "NULL"
        }
        return String(cString: v)
    }
    
    
}
