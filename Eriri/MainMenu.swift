//
//  MainMenu.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/27.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import VLCKit

class MainMenu: NSObject, NSMenuItemValidation {
    var delegate: AppDelegate? {
        return NSApp.delegate as? AppDelegate
    }
    
    var playerContainer: EririPlayer? {
        return Utils.shared.players.first(where: {
            $0.window == NSApp.keyWindow
        })
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true
    }

// MARK: - Eriri
    
    @IBAction func about(_ sender: NSMenuItem) {
    }
    
    @IBAction func preferences(_ sender: NSMenuItem) {
    }
    
    
// MARK: - File
    @IBAction func open(_ sender: NSMenuItem) {
        delegate?.showMediaOpenPanel()
    }
    
    @IBAction func openUrl(_ sender: NSMenuItem) {
    }
    
// MARK: - Playback
    
    @IBAction func play(_ sender: NSMenuItem) {
        playerContainer?.player.togglePlay()
    }
    
    @IBAction func stepForward5S(_ sender: NSMenuItem) {
        // extraShortJumpForward    3s
        // shortJumpForward         10s
        // mediumJumpForward        1min
        // longJumpForward          5min
        playerContainer?.player.jumpForward(5)
    }
    
    @IBAction func stepBackward5S(_ sender: NSMenuItem) {
        playerContainer?.player.jumpBackward(5)
    }
    
    @IBAction func nextChapter(_ sender: NSMenuItem) {
        playerContainer?.player.nextChapter()
    }
    
    @IBAction func previousChapter(_ sender: NSMenuItem) {
        playerContainer?.player.previousChapter()
    }
    
// MARK: - Audio
    
    @IBAction func increaseVolume(_ sender: NSMenuItem) {
        guard let p = playerContainer?.player else { return }
        var v = p.audio.volume + 5
        if v > 100 {
            v = 100
        }
        p.audio.volume = v
    }
    
    @IBAction func decreaseVolume(_ sender: NSMenuItem) {
        guard let p = playerContainer?.player else { return }
        var v = p.audio.volume - 5
        if v < 0 {
            v = 0
        }
        p.audio.volume = v
    }
    
    @IBAction func mute(_ sender: NSMenuItem) {
        guard let p = playerContainer?.player else { return }
        p.audio.isMuted = !p.audio.isMuted
    }
    
    
// MARK: - Video

    @IBAction func halfSize(_ sender: NSMenuItem) {
        guard let c = playerContainer else { return }
        var s = c.player.videoSize
        s.width /= 2
        s.height /= 2
        c.window.setContentSize(s)
    }
    
    @IBAction func normalSize(_ sender: NSMenuItem) {
        guard let c = playerContainer else { return }
        let s = c.player.videoSize
        c.window.setContentSize(s)
    }
    
    @IBAction func doubleSize(_ sender: NSMenuItem) {
        guard let c = playerContainer else { return }
        var s = c.player.videoSize
        s.width *= 2
        s.height *= 2
        c.window.setContentSize(s)
    }
    
    @IBAction func fitToScreen(_ sender: NSMenuItem) {
        
        
    }
    
    @IBAction func increaseSize(_ sender: NSMenuItem) {
    }
    
    @IBAction func decreaseSize(_ sender: NSMenuItem) {
    }
    
    @IBAction func floatOnTop(_ sender: NSMenuItem) {
    }
    
    @IBAction func snapshot(_ sender: NSMenuItem) {
    }
    
// MARK: - Window
    
    @IBAction func info(_ sender: NSMenuItem) {
        let utils = Utils.shared
        utils.vlcInfos.start()
        utils.infoPanel.center()
        utils.infoPanel.makeKeyAndOrderFront(sender)
    }
}
