//
//  UtilsVLCProtocolExtension.swift
//  Eriri
//
//  Created by xjbeta on 2020/2/4.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import VLCKit

extension Utils: VLCLibraryLogReceiverProtocol {
    func handleMessage(_ message: String, debugLevel level: Int32) {
        print("VLCKit Log: \(message)")
    }
}

extension Utils: VLCCustomDialogRendererProtocol {
    func showError(withTitle error: String, message: String) {
        print(#function, message)
    }
    
    func showLogin(withTitle title: String, message: String, defaultUsername username: String?, askingForStorage: Bool, withReference reference: NSValue) {
        print(#function, message)
    }
    
    func showQuestion(withTitle title: String, message: String, type questionType: VLCDialogQuestionType, cancel cancelString: String?, action1String: String?, action2String: String?, withReference reference: NSValue) {
        print(#function, message)
    }
    
    func showProgress(withTitle title: String, message: String, isIndeterminate: Bool, position: Float, cancel cancelString: String?, withReference reference: NSValue) {
        print(#function, message)
    }
    
    func updateProgress(withReference reference: NSValue, message: String?, position: Float) {
        print(#function, message)
    }
    
    func cancelDialog(withReference reference: NSValue) {
        print(#function)
    }
    
    
}
