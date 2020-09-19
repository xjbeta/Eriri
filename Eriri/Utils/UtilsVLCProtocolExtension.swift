//
//  UtilsVLCProtocolExtension.swift
//  Eriri
//
//  Created by xjbeta on 2020/2/4.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa

//extension Utils: VLCLibraryLogReceiverProtocol {
//    func handleMessage(_ message: String, debugLevel level: Int32) {
//        print("VLCKit Log: \(message)")
//    }
//}

extension Utils: VLCDialogRendererDelegate {
    
    func showError(withTitle error: String, message: String) {
        print("Dialog Renderer", #function, message)
    }
    
    func showLogin(withTitle title: String, message: String, defaultUsername username: String?, askingForStorage: Bool, withReference reference: OpaquePointer) {
        print("Dialog Renderer", #function, message)
        
        let info = LoginViewInfo()
        info.title = title
        info.message = message
        info.username = username ?? ""
        info.askingForStorage = askingForStorage
        DispatchQueue.main.async {
            self.openLoginPanel(info) {
                VLCLibrary.shared.postDialog(info.username, and: info.password, for: reference, store: info.storePassword)
            }
        }
    }
    
    func showQuestion(withTitle title: String, message: String, type questionType: VLCDialogQuestionType, cancel cancelString: String?, action1String: String?, action2String: String?, withReference reference: OpaquePointer) {
        print("Dialog Renderer", #function, message)
    }
    
    func showProgress(withTitle title: String, message: String, isIndeterminate: Bool, position: Float, cancel cancelString: String?, withReference reference: OpaquePointer) {
        print("Dialog Renderer", #function, message)
    }
    
    func updateProgress(withReference reference: NSValue, message: String?, position: Float) {
        print("Dialog Renderer", #function, message ?? "")
    }
    
    func cancelDialog(withReference reference: OpaquePointer) {
        print("Dialog Renderer", #function)
    }
    
    
}
