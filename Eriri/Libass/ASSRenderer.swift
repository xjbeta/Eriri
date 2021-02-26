//
//  ASSRenderer.swift
//  Eriri
//
//  Created by xjbeta on 2/22/21.
//  Copyright © 2021 xjbeta. All rights reserved.
//

import Foundation
import Metal
import MetalKit

class ASSRenderer: NSObject {
    
    let mtkView: MTKView
    
    // Metal
    var device: MTLDevice!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var defaultLibrary: MTLLibrary!
    var textureDescriptor: MTLTextureDescriptor!
    var texture: MTLTexture!
    
    var viewPortSize = vector_uint2.zero
    var vertexs = [ASSVertex]()
    
    // Libass
    let libass: Libass
    var lastRequestTime: Int64 = -1
    var subtitleDaily: Int64 = 0 {
        didSet {
            mtkView.draw()
        }
    }
    
    var position: Int = 0 {
        didSet {
//            mtkViewTopLC.constant = CGFloat(-position)
        }
    }
    
    
    init(_ mtkView: MTKView, _ url: String) {
        libass = Libass(size: .zero)
        self.mtkView = mtkView
        
        super.init()
        
        libass.setFile(url)
        
        device = MTLCreateSystemDefaultDevice()
        mtkView.device = device
        
        mtkView.preferredFramesPerSecond = 30
        mtkView.delegate = self
        mtkView.layer?.isOpaque = false
        
        textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .bgra8Unorm
        texture = device.makeTexture(descriptor: textureDescriptor)

        defaultLibrary = device.makeDefaultLibrary()
        let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary.makeFunction(name: "samplingShader")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        
        pipelineStateDescriptor.label = "Texturing Pipeline"
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            print(error)
        }
    
        commandQueue = device.makeCommandQueue()
        
        mtkView.isPaused = true
    }
    
    func update(_ ms: Int64) {
        loadNewASSImage(ms)
        drawTexture(in: mtkView)
        
        mtkView.draw()
    }
    
}

extension ASSRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewPortSize.x = UInt32(size.width)
        viewPortSize.y = UInt32(size.height)
    
        textureDescriptor.width = Int(viewPortSize.x)
        textureDescriptor.height = Int(viewPortSize.y)
        
        texture = device.makeTexture(descriptor: textureDescriptor)
        updateVertexs()
        
        libass.setSize(size)
    }
    
    func draw(in view: MTKView) {
        
    }
    
    func loadNewASSImage(_ ms: Int64) {
        
        let time = ms + subtitleDaily
        
        guard lastRequestTime != time,
              let image = libass.generateImage(time) else { return }
        
        let bytesPerRow = Int(viewPortSize.x * 4)
        
        let region = MTLRegion(
            origin: MTLOrigin(x: 0, y: 0, z: 0),
            size: MTLSize(width: textureDescriptor.width,
                          height: textureDescriptor.height,
                          depth: 1))
        
        texture.replace(region: region,
                        mipmapLevel: 0,
                        withBytes: image.buffer,
                        bytesPerRow: bytesPerRow)
        
        image.buffer.deallocate()
        
        lastRequestTime = time
    }
    
    func drawTexture(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
              let drawable = view.currentDrawable else {
            return
        }
        
        // Load textures

        let buffer = device.makeBuffer(
            bytes: vertexs,
            length: MemoryLayout<ASSVertex>.stride * vertexs.count,
            options: .storageModeShared)
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 0, 1)
        
        commandEncoder.label = "ASS encoder"
        commandEncoder.setViewport(
            MTLViewport(originX: 0.0,
                        originY: 0.0,
                        width: Double(viewPortSize.x),
                        height: Double(viewPortSize.y),
                        znear: -1.0,
                        zfar: 1.0))
        commandEncoder.setRenderPipelineState(pipelineState)
        commandEncoder.setVertexBytes(&viewPortSize, length: MemoryLayout<vector_uint2>.stride, index: ASSVertexInputIndex.ViewporSize.rawValue)
        
        commandEncoder.setVertexBuffer(buffer, offset: 0, index: ASSVertexInputIndex.Vertices.rawValue)
        commandEncoder.setFragmentTexture(texture, index: ASSTextureIndex.BaseColor.rawValue)
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexs.count)
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func updateVertexs() {
        let hw = Float(viewPortSize.x / 2)
        let hh = Float(viewPortSize.y / 2)
        
        let topLeft = ASSVertex(
            (-hw, hh),
            (0.0, 0.0))
        
        let topRight = ASSVertex(
            (hw, hh),
            (1.0, 0.0))
        
        let bottomLeft = ASSVertex(
            (-hw, -hh),
            (0.0, 1.0))
        let bottomRight = ASSVertex(
            (hw, -hh),
            (1.0, 1.0))
        
        
        vertexs = [
            bottomRight,
            bottomLeft,
            topLeft,
            
            bottomRight,
            topLeft,
            topRight]
    }
}