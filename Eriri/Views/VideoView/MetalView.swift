//
//  MetalView.swift
//  QuickTime ASS
//
//  Created by xjbeta on 2/16/21.
//

import SwiftUI
import MetalKit

struct MetalView: NSViewRepresentable {
    let mtkView: MTKView
    
    func makeNSView(context: Context) -> MTKView {
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
    }
    
}
