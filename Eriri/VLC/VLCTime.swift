//
//  VLCTime.swift
//  Eriri
//
//  Created by xjbeta on 2020/2/9.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa

class VLCTime: NSObject {
    var value: Int64 = 0
    
    init(with milliseconds: Int64) {
        value = milliseconds
    }
    
    func stringValue() -> String {
        let d = "--:--"
        let seconds = Int(value / 1000)
        
        let formatter = DateComponentsFormatter()
        
        formatter.allowedUnits = seconds >= 3600 ?  [.hour, .minute, .second] : [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: .init(seconds)) ?? d
    }
}
