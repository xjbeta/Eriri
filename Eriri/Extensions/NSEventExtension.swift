//
//  NSEventExtension.swift
//  Eriri
//
//  Created by xjbeta on 2020/2/12.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa

extension NSEvent {
    func isIn(views: [NSView?]) -> Bool {
        return views.compactMap {
            $0
        }.filter {
            $0.isMousePoint($0.convert(self.locationInWindow, from: nil), in: $0.bounds)
        }.count > 0
    }
}
