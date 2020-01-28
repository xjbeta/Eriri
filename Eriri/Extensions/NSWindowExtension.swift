//
//  NSWindowExtension.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/28.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa

extension NSWindow {
    func hideTitlebar(_ hide: Bool) {
        titleView()?.isHidden = hide
    }
    
    func titleView() -> NSView? {
        return standardWindowButton(.closeButton)?.superview?.superview
    }
}
