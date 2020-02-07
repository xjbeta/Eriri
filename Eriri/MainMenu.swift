//
//  MainMenu.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/27.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import VLCKit

class MainMenu: NSObject, NSMenuItemValidation, NSMenuDelegate {
    var appDelegate: AppDelegate? {
        return NSApp.delegate as? AppDelegate
    }
    
    var currentPlayer: EririPlayer? {
        return Utils.shared.players.first(where: {
            $0.window == NSApp.keyWindow
        })
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard let player = currentPlayer?.player else { return }
        menu.removeAllItems()
        switch menu {
        case subtitleListMenu:
            let subtitles = player.subtitles()
            let current = Int(player.currentVideoSubTitleIndex)
            subtitles.forEach {
                let item = NSMenuItem()
                item.title = $0.name
                item.tag = $0.index
                item.target = self
                item.action = #selector(self.subtitleItemAction(_:))
                if $0.index == current {
                    item.state = .on
                }
                menu.addItem(item)
            }
        case audioTrackMenu:
            let tracks = player.audioTracks()
            let current = Int(player.currentAudioTrackIndex)
            tracks.forEach {
                let item = NSMenuItem()
                item.title = $0.name
                item.tag = $0.index
                item.target = self
                item.action = #selector(self.audioTrackItemAction(_:))
                if $0.index == current {
                    item.state = .on
                }
                menu.addItem(item)
            }
        default:
            break
        }
        
        
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem {
        case aboutMenuItem, preferencesMenuItem, openMenuItem, openUrlMenuItem:
            return true
            
        case playMenuItem, stepForwardMenuItem, stepBackwardMenuItem, nextChapterMenuItem, previousChapterMenuItem:
            guard let player = currentPlayer else { return false }
            return true
            
        case decreaseVolumeMenuItem, increaseVolumeMenuItem, muteMenuItem:
            guard let player = currentPlayer else { return false }
            return true
            
        case halfSizeMenuItem, normalSizeMenuItem, doubleSizeMenuItem, fitToScreenMenuItem, increaseSizeMenuItem, decreaseSizeMenuItem, floatOnTopMenuItem, snapshotMenuItem:
            
            guard let player = currentPlayer else { return false }
            return true
            
        case addSubtitleFileMenuItem, subtitlesMenuItem:
            guard let player = currentPlayer else { return false }
            return true
            
        case infoMenuItem:
            guard let player = currentPlayer else { return false }
            return true
            
        case _ where menuItem.menu == subtitleListMenu:
            return true
        case _ where menuItem.menu == audioTrackMenu:
            return true
        default:
            break
        }
        return false
    }

// MARK: - Eriri
    
    @IBOutlet weak var aboutMenuItem: NSMenuItem!
    @IBAction func about(_ sender: NSMenuItem) {
    }
    
    @IBOutlet weak var preferencesMenuItem: NSMenuItem!
    @IBAction func preferences(_ sender: NSMenuItem) {
    }
    
    
// MARK: - File
    @IBOutlet weak var openMenuItem: NSMenuItem!
    @IBAction func open(_ sender: NSMenuItem) {
        appDelegate?.showMediaOpenPanel()
    }
    
    @IBOutlet weak var openUrlMenuItem: NSMenuItem!
    @IBAction func openUrl(_ sender: NSMenuItem) {
        let w = Utils.shared.openURLPanel
        w.makeKeyAndOrderFront(self)
    }
    
// MARK: - Playback
    
    @IBOutlet weak var playbackMenu: NSMenu!
    @IBOutlet weak var playMenuItem: NSMenuItem!
    @IBAction func play(_ sender: NSMenuItem) {
        currentPlayer?.player.togglePlay()
    }
    
    @IBOutlet weak var stepForwardMenuItem: NSMenuItem!
    @IBAction func stepForward5S(_ sender: NSMenuItem) {
        // extraShortJumpForward    3s
        // shortJumpForward         10s
        // mediumJumpForward        1min
        // longJumpForward          5min
        
        currentPlayer?.player.seek(5)
    }
    
    @IBOutlet weak var stepBackwardMenuItem: NSMenuItem!
    @IBAction func stepBackward5S(_ sender: NSMenuItem) {
        
        currentPlayer?.player.seek(-5)
    }
    
    @IBOutlet weak var nextChapterMenuItem: NSMenuItem!
    @IBAction func nextChapter(_ sender: NSMenuItem) {
        currentPlayer?.player.nextChapter()
    }
    
    @IBOutlet weak var previousChapterMenuItem: NSMenuItem!
    @IBAction func previousChapter(_ sender: NSMenuItem) {
        currentPlayer?.player.previousChapter()
    }
    
// MARK: - Audio
    
    @IBOutlet weak var audioMenu: NSMenu!
    @IBOutlet weak var increaseVolumeMenuItem: NSMenuItem!
    @IBAction func increaseVolume(_ sender: NSMenuItem) {
        guard let p = currentPlayer?.player else { return }
        var v = p.audio.volume + 5
        if v > 100 {
            v = 100
        }
        p.audio.volume = v
    }
    
    @IBOutlet weak var decreaseVolumeMenuItem: NSMenuItem!
    @IBAction func decreaseVolume(_ sender: NSMenuItem) {
        guard let p = currentPlayer?.player else { return }
        var v = p.audio.volume - 5
        if v < 0 {
            v = 0
        }
        p.audio.volume = v
    }
    
    @IBOutlet weak var muteMenuItem: NSMenuItem!
    @IBAction func mute(_ sender: NSMenuItem) {
        guard let p = currentPlayer?.player else { return }
        p.audio.isMuted = !p.audio.isMuted
    }
    
    @IBOutlet weak var audioTrackMenu: NSMenu!
    
    @IBAction func audioTrackItemAction(_ sender: NSMenuItem) {
        currentPlayer?.player.currentAudioTrackIndex = Int32(sender.tag)
    }
    
// MARK: - Video

    @IBOutlet weak var videoMenu: NSMenu!
    @IBOutlet weak var halfSizeMenuItem: NSMenuItem!
    @IBAction func halfSize(_ sender: NSMenuItem) {
        guard let c = currentPlayer else { return }
        var s = c.player.videoSize
        s.width /= 2
        s.height /= 2
        c.window.setContentSize(s)
    }
    
    @IBOutlet weak var normalSizeMenuItem: NSMenuItem!
    @IBAction func normalSize(_ sender: NSMenuItem) {
        guard let c = currentPlayer else { return }
        let s = c.player.videoSize
        c.window.setContentSize(s)
    }
    
    @IBOutlet weak var doubleSizeMenuItem: NSMenuItem!
    @IBAction func doubleSize(_ sender: NSMenuItem) {
        guard let c = currentPlayer else { return }
        var s = c.player.videoSize
        s.width *= 2
        s.height *= 2
        c.window.setContentSize(s)
    }
    
    @IBOutlet weak var fitToScreenMenuItem: NSMenuItem!
    @IBAction func fitToScreen(_ sender: NSMenuItem) {
        
        
    }
    
    @IBOutlet weak var increaseSizeMenuItem: NSMenuItem!
    @IBAction func increaseSize(_ sender: NSMenuItem) {
    }
    
    @IBOutlet weak var decreaseSizeMenuItem: NSMenuItem!
    @IBAction func decreaseSize(_ sender: NSMenuItem) {
    }
    
    @IBOutlet weak var floatOnTopMenuItem: NSMenuItem!
    @IBAction func floatOnTop(_ sender: NSMenuItem) {
    }
    
    @IBOutlet weak var snapshotMenuItem: NSMenuItem!
    @IBAction func snapshot(_ sender: NSMenuItem) {
    }
    
// MARK: - Subtitles
    
    @IBOutlet weak var subtitlesMenu: NSMenu!
    @IBOutlet weak var subtitleListMenu: NSMenu!
    @IBOutlet weak var subtitlesMenuItem: NSMenuItem!
    
    @IBOutlet weak var addSubtitleFileMenuItem: NSMenuItem!
    @IBAction func addSubtitleFile(_ sender: NSMenuItem) {
        
        
    }
    
    @IBAction func subtitleItemAction(_ sender: NSMenuItem) {
        currentPlayer?.player.currentVideoSubTitleIndex = Int32(sender.tag)
    }
    
    
// MARK: - Window
    
    @IBOutlet weak var infoMenuItem: NSMenuItem!
    @IBAction func info(_ sender: NSMenuItem) {
        let utils = Utils.shared
        utils.vlcInfos.start()
        utils.infoPanel.center()
        utils.infoPanel.makeKeyAndOrderFront(sender)
    }
}
