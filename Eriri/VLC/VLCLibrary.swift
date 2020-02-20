//
//  VLCLibrary.swift
//  Eriri
//
//  Created by xjbeta on 2020/2/9.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import Darwin

enum VLCDialogQuestionType: Int {
    case normal
    case warning
    case critical
}

protocol VLCDialogRendererDelegate {
    func showError(withTitle error: String, message: String)
    func showLogin(withTitle title: String, message: String, defaultUsername username: String?, askingForStorage: Bool, withReference reference: OpaquePointer)
    func showQuestion(withTitle title: String, message: String, type questionType: VLCDialogQuestionType, cancel cancelString: String?, action1String: String?, action2String: String?, withReference reference: OpaquePointer)
    func showProgress(withTitle title: String, message: String, isIndeterminate: Bool, position: Float, cancel cancelString: String?, withReference reference: OpaquePointer)
    func updateProgress(withReference reference: NSValue, message: String?, position: Float)
    func cancelDialog(withReference reference: OpaquePointer)
}

class VLCLibrary: NSObject {
    static let shared = VLCLibrary()
    var instance: OpaquePointer?
    
    private var enableLogging = false
    
    
    var dialogDelegate: VLCDialogRendererDelegate? {
        didSet {
            if dialogDelegate == nil {
                deinitDialogCallbacks()
            } else {
                initDialogCallbacks()
            }
        }
    }
    
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
        let path = "/Applications/VLC.app/Contents/MacOS/plugins"
        
//        let path = Bundle.main.bundlePath + "/Contents/Frameworks/plugins"
        
        if setenv("VLC_PLUGIN_PATH", path, 1) != 0 {
            print("Set plugins path error \(errno)")
        }
        
        let options = defaultOptions
        let argv: [UnsafePointer<Int8>?] = options.map({ $0.withCString({ $0 }) })
        
        instance = libvlc_new(Int32(options.count), argv)
        
        libvlc_set_app_id(instance, "com.xjbeta.Eriri", "1.0", "foobar")
    }
    
    enum LogLevel: Int32 {
        case info = 0
        case error = 1
        case warning = 2
        case debug = 4
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
            
            print("VLC LOG: \(s.toString())")
            
        }, Unmanaged.passUnretained(self).toOpaque())
    }
    
    func version() -> String {
        guard let v = libvlc_get_version() else {
            return "NULL"
        }
        return v.toString()
    }
    
    
    // MARK: - Dialog
    
    func postDialog(_ username: String,
                    and password: String,
                    for reference: OpaquePointer,
                    store: Bool) {
        
        
        libvlc_dialog_post_login(reference, username.cString(), password.cString(), store)
    }
    
    func initDialogCallbacks() {
        guard let _ = dialogDelegate else { return }
        var cbs = libvlc_dialog_cbs(pf_display_error: { (data, title, text) in
            guard let d = data else { return }
            let l = Unmanaged<VLCLibrary>.fromOpaque(d).takeUnretainedValue()
            guard let dd = l.dialogDelegate else { return }
            dd.showError(withTitle: title?.toString() ?? "", message: text?.toString() ?? "")
        }, pf_display_login: { (data, id, title, text, username, askStore) in
            guard let d = data, let id = id else { return }
            let l = Unmanaged<VLCLibrary>.fromOpaque(d).takeUnretainedValue()
            guard let dd = l.dialogDelegate else { return }
            
            dd.showLogin(withTitle: title?.toString() ?? "", message: text?.toString() ?? "", defaultUsername: username?.toString() ?? "", askingForStorage: askStore, withReference: id)
        }, pf_display_question: { (data, id, title, text, type, cancel, action1, action2) in
            guard let d = data, let id = id else { return }
            let l = Unmanaged<VLCLibrary>.fromOpaque(d).takeUnretainedValue()
            guard let dd = l.dialogDelegate else { return }
            
            var t = VLCDialogQuestionType.normal
            switch type {
            case LIBVLC_DIALOG_QUESTION_NORMAL:
                t = .normal
            case LIBVLC_DIALOG_QUESTION_WARNING:
                t = .warning
            case LIBVLC_DIALOG_QUESTION_CRITICAL:
                t = .critical
            default:
                return
            }
            
            dd.showQuestion(withTitle: title?.toString() ?? "", message: text?.toString() ?? "", type: t, cancel: cancel?.toString(), action1String: action1?.toString(), action2String: action2?.toString(), withReference: id)
        }, pf_display_progress: { (data, id, title, text, indeterminate, position, cancel) in
            guard let d = data, let id = id else { return }
            let l = Unmanaged<VLCLibrary>.fromOpaque(d).takeUnretainedValue()
            guard let dd = l.dialogDelegate else { return }
            
            dd.showProgress(withTitle: title?.toString() ?? "", message: text?.toString() ?? "", isIndeterminate: indeterminate, position: position, cancel: cancel?.toString(), withReference: id)
        }, pf_cancel: { (data, id) in
            guard let d = data, let id = id else { return }
            let l = Unmanaged<VLCLibrary>.fromOpaque(d).takeUnretainedValue()
            guard let dd = l.dialogDelegate else { return }
            dd.cancelDialog(withReference: id)
        }, pf_update_progress: { (data, id, position, text) in
            guard let d = data else { return }
            let l = Unmanaged<VLCLibrary>.fromOpaque(d).takeUnretainedValue()
            guard let dd = l.dialogDelegate else { return }
            
            dd.updateProgress(withReference: NSValue(pointer: UnsafeRawPointer(id)), message: text?.toString(), position: position)
        })
        
        let s = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        libvlc_dialog_set_callbacks(instance, &cbs, s)
    }
    
    func deinitDialogCallbacks() {
        libvlc_dialog_set_callbacks(instance, nil, nil)
    }
}
