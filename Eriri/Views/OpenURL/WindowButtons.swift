//
//  WindowButtons.swift
//  Eriri
//
//  Created by xjbeta on 2020/2/4.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import SwiftUI
import AppKit

struct WindowButtons: NSViewRepresentable {
    let window: NSWindow
    let title: String
    let returnAction: (() -> Void)
    
    let cancelButton = NSButton()
    let okButton = NSButton()
    
    enum KeyEquivalent: String {
        case escape = "\u{1b}"
        case `return` = "\r"
    }

    func makeNSView(context: Context) -> NSStackView {
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = KeyEquivalent.escape.rawValue
        
        okButton.title = title
        okButton.bezelStyle = .rounded
        okButton.keyEquivalent = KeyEquivalent.return.rawValue
        
        let stackView = NSStackView(views: [NSView(), cancelButton, okButton])
        
        stackView.orientation = .horizontal
        
        okButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor, multiplier: 1).isActive = true
        okButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: 20).isActive = true
        
        return stackView
    }
    
    
    func updateNSView(_ nsView: NSStackView, context: Context) {

    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    

    final class Coordinator: NSObject {
        var control: WindowButtons
        init(_ control: WindowButtons) {
            self.control = control
            super.init()
            control.okButton.target = self
            control.okButton.action = #selector(self.buttonActions(_:))
            control.cancelButton.target = self
            control.cancelButton.action = #selector(self.buttonActions(_:))
        }
        
        @IBAction func buttonActions(_ sender: NSButton) {
            switch sender {
            case control.okButton:
                control.returnAction()
            case control.cancelButton:
                control.window.close()
            default:
                break
            }
        }
    }
}
