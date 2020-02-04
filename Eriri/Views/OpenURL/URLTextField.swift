//
//  URLTextField.swift
//  Eriri
//
//  Created by xjbeta on 2020/2/4.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import SwiftUI
import AppKit

struct URLTextField: NSViewRepresentable {
    let textField = NSTextField()
    let window: NSWindow
    
    @Binding var stringValue: String

    func makeNSView(context: Context) -> NSTextField {
         textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        
        textField.lineBreakMode = .byWordWrapping
        textField.delegate = context.coordinator
        textField.autoresizingMask = [.height, .width]
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {

    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    

    final class Coordinator: NSObject, NSTextFieldDelegate, NSWindowDelegate {
        var control: URLTextField
        init(_ control: URLTextField) {
            self.control = control
            super.init()
            self.control.window.delegate = self
        }
        
        func controlTextDidChange(_ obj: Notification) {
            control.stringValue = control.textField.stringValue
        }
        
        func windowDidBecomeKey(_ notification: Notification) {
            control.window.makeFirstResponder(control.textField)
        }
    }
}
