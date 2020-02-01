//
//  VisualEffectView.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/26.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import SwiftUI

struct VisualEffectView: NSViewRepresentable {
    private let view: NSVisualEffectView
    
    init(material: NSVisualEffectView.Material,
         blendingMode: NSVisualEffectView.BlendingMode) {
        view = NSVisualEffectView()
        view.material = material
        view.state = .active
        view.blendingMode = blendingMode
    }
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // Nothing to do.
    }
}
