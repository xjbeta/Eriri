//
//  MainMenu.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/27.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa

class MainMenu: NSObject, NSMenuItemValidation, NSMenuDelegate {
    
    let snapshotPath = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first?.appendingPathComponent("Screenshots", isDirectory: true)
    
    var appDelegate: AppDelegate? {
        return NSApp.delegate as? AppDelegate
    }
    
    var currentPlayer: EririPlayer? {
        return Utils.shared.players.first(where: {
            $0.window == NSApp.keyWindow
        })
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard let p = currentPlayer,
              let mp = p.player.mediaPlayer else { return }
        
        vlc_mutex_lock(&mp.pointee.input.lock)
        let it = mp.pointee.input.p_thread
        vlc_mutex_unlock(&mp.pointee.input.lock)
        guard let inputThread = it else { return }
        
        let inputThreadObj = VLCObject(inputThread: inputThread).vlcObject()
        
        switch menu {
        case subtitlesMenu:
            let v = p.player.currentVideoSubTitleDelay()
            
            subtitleDelayMenuItem.title = "Subtitle Delay: \(v)s"
            
            setupVarMenuItem(subtitleTrackMenuItem,
                             target: inputThreadObj,
                             variable: "spu-es",
                             selector: #selector(toggleVar))
            
        case audioMenu:
            let v = p.player.currentAudioPlaybackDelay()
            audioDelayMenuItem.title = "Audio Delay: \(v)s"
            
            if let aout = input_resource_HoldAout(mp.pointee.input.p_resource) {
                let obj = VLCObject(audioOutput: aout).vlcObject()

                setupVarMenuItem(stereoAudioModeMenuItem,
                                 target: obj,
                                 variable: "stereo-mode",
                                 selector: #selector(toggleVar))
                setupVarMenuItem(visualizationsMenuItem,
                                 target: obj,
                                 variable: "visual",
                                 selector: #selector(toggleVar))
            }
            

            setupVarMenuItem(audioTrackMenuItem,
                             target: inputThreadObj,
                             variable: "audio-es",
                             selector: #selector(toggleVar))
            
            refreshAudioDeviceList()
            
        case videoMenu:
            floatOnTopMenuItem.state = p.window.level == .floating ? .on : .off
            
            

            
            if let vout = input_GetVout(inputThread) {
                let obj = VLCObject(voutThread: vout).vlcObject()
            
                setupVarMenuItem(aspectRatioMenuItem,
                                 target: obj,
                                 variable: "aspect-ratio",
                                 selector: #selector(toggleVar))
                setupVarMenuItem(cropMenuItem,
                                 target: obj,
                                 variable: "crop",
                                 selector: #selector(toggleVar))
                setupVarMenuItem(deinterlaceMenuItem,
                                 target: obj,
                                 variable: "deinterlace",
                                 selector: #selector(toggleVar))
                setupVarMenuItem(deinterlaceModeMenuItem,
                                 target: obj,
                                 variable: "deinterlace-mode",
                                 selector: #selector(toggleVar))
            }
            
            setupVarMenuItem(videoTrackMenuItem,
                             target: inputThreadObj,
                             variable: "video-es",
                             selector: #selector(toggleVar))
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
            
        case decreaseVolumeMenuItem, increaseVolumeMenuItem, muteMenuItem, audioDelayDecreaseMenuItem, audioDelayIncreaseMenuItem, resetAudioDelayMenuItem:
            guard let player = currentPlayer else { return false }
            return true
            
        case halfSizeMenuItem, normalSizeMenuItem, doubleSizeMenuItem, fitToScreenMenuItem, floatOnTopMenuItem, snapshotMenuItem:
            
            guard let player = currentPlayer else { return false }
            return true
            
        case addSubtitleFileMenuItem, subtitleDelayDecreaseMenuItem, subtitleDelayIncreaseMenuItem,
             resetSubtitleDelayMenuItem:
            guard let player = currentPlayer else { return false }
            return true
            
            
        case subtitleScaleIncreaseMenuItem,
                 subtitleScaleDecreaseMenuItem, resetSubtitleScaleMenuItem:
                guard let player = currentPlayer else { return false }
                
                return true
            
        case infoMenuItem:
            guard let player = currentPlayer else { return false }
            return true
            
        case snapshotFolderMenuItem:
            return true
            
        case _ where menuItem.menu == subtitleTrackMenuItem.submenu:
            return true
            
        case aspectRatioMenuItem:
            return true
        case _ where menuItem.menu == aspectRatioMenuItem.submenu:
            return true
        case cropMenuItem:
            return true
        case _ where menuItem.menu == cropMenuItem.submenu:
            return true
        case deinterlaceMenuItem:
            return true
        case _ where menuItem.menu == deinterlaceMenuItem.submenu:
            return true
        case deinterlaceModeMenuItem:
            return true
        case _ where menuItem.menu == deinterlaceModeMenuItem.submenu:
            return true
        case videoTrackMenuItem:
            return true
        case _ where menuItem.menu == videoTrackMenuItem.submenu:
            return true


        case audioTrackMenuItem:
            return true
        case _ where menuItem.menu == audioTrackMenuItem.submenu:
            return true
        case stereoAudioModeMenuItem:
            return true
        case _ where menuItem.menu == stereoAudioModeMenuItem.submenu:
            return true
        case visualizationsMenuItem:
            return true
        case _ where menuItem.menu == visualizationsMenuItem.submenu:
            return true
        case audioDeviceMenuItem:
            return true
        case _ where menuItem.menu == audioDeviceMenuItem.submenu:
            return true
        default:
            break
        }
        return false
    }
    
    @objc func toggleVar(_ sender: NSMenuItem) {
        let data = sender.representedObject
        Thread.detachNewThreadSelector(#selector(toggleVarThread), toTarget: self, with: data)
    }
    
    @objc func toggleVarThread(_ data: Any?) {
        guard let content = data as? VLCAutoGeneratedMenuContent,
              let obj = content.object else { return }
        
        var_Set(obj, content.name, content.value)
        vlc_object_release(obj)
    }
    
    
// MARK: - Dynamic menu creation and validation
    
    func setupVarMenuItem(_ mi: NSMenuItem,
                          target object: UnsafeMutablePointer<vlc_object_t>!,
                          variable: String,
                          selector callback: Selector) {
        
//        var_Type(object, "variable".cString())
        
        let type = var_Type(object, variable.cString())
        
        switch type & VLC_VAR_TYPE {
        case VLC_VAR_VOID,
             VLC_VAR_BOOL,
             VLC_VAR_STRING,
             VLC_VAR_INTEGER:
            break
        default:
            print("variable \(variable) doesn't exist or isn't handled")
            return
        }
        
        var text = vlc_value_t()
        
        var_Change(object, variable, VLC_VAR_GETTEXT, &text, nil)
        mi.title = text.psz_string != nil ? text.psz_string.toString() : variable
        
        if (type & VLC_VAR_HASCHOICE) != 0 {
            setupVarMenu(for: mi,
                         target: object,
                         variable: variable,
                         selector: callback)
        }
        
        
        
    }
    
    func setupVarMenu(for mi: NSMenuItem,
                      target object: UnsafeMutablePointer<vlc_object_t>!,
                      variable: String,
                      selector callback: Selector) {
        guard let menu = mi.submenu else { return }
        menu.removeAllItems()
        mi.isEnabled = false
        /* Aspect Ratio  todo */
        
        let type = var_Type(object, variable)
        
        var val = vlc_value_t()
        var_Change(object, variable, VLC_VAR_CHOICESCOUNT, &val, nil)
        if val.i_int == 0 || val.i_int == 1 {
            return
        }
        
        if var_Get(object, variable, &val) < 0 {
            return
        }
        
        var valList = vlc_value_t()
        var textList = vlc_value_t()
        if var_Change(object, variable, VLC_VAR_GETCHOICES,
                      &valList, &textList) < 0 {
            return
        }
        
        let c = Int(valList.p_list.pointee.i_count)
        mi.isEnabled = c > 0
        
        (0..<c).forEach {
            let item = NSMenuItem()
            item.title = ""
            let textV = textList.p_list.pointee.p_values[$0]
            let valV = valList.p_list.pointee.p_values[$0]
            
            switch (type & VLC_VAR_TYPE) {
            case VLC_VAR_STRING:
                item.title = textV.psz_string != nil ? textV.psz_string.toString() : valV.psz_string.toString()
                item.action = callback
                item.target = self
                let data = VLCAutoGeneratedMenuContent(variable, of: object, and: valV, of: Int(type))
                item.representedObject = data
                menu.addItem(item)
                
                if strcmp(val.psz_string, valV.psz_string) == 0 {
                    item.state = .on
                }
            case VLC_VAR_INTEGER:
                item.title = textV.psz_string != nil ? textV.psz_string.toString() : "\(textV.i_int)"
                item.action = callback
                item.target = self
                let data = VLCAutoGeneratedMenuContent(variable, of: object, and: valV, of: Int(type))
                item.representedObject = data
                menu.addItem(item)
                
                if valV.i_int == val.i_int {
                    item.state = .on
                }
            default:
                break
            }
            
        }
        
        valList.p_address.deallocate()
        textList.p_address.deallocate()
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
        currentPlayer?.player.seek(5, false)
    }
    
    @IBOutlet weak var stepBackwardMenuItem: NSMenuItem!
    @IBAction func stepBackward5S(_ sender: NSMenuItem) {
        currentPlayer?.player.seek(-5, false)
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
        p.volume += 5
    }
    
    @IBOutlet weak var decreaseVolumeMenuItem: NSMenuItem!
    @IBAction func decreaseVolume(_ sender: NSMenuItem) {
        guard let p = currentPlayer?.player else { return }
        p.volume -= 5
    }
    
    @IBOutlet weak var muteMenuItem: NSMenuItem!
    @IBAction func mute(_ sender: NSMenuItem) {
        guard let p = currentPlayer?.player else { return }
        p.toggleMute()
    }
    
    
    @IBOutlet weak var audioDelayMenuItem: NSMenuItem!
    
    @IBOutlet weak var audioDelayIncreaseMenuItem: NSMenuItem!
    @IBAction func audioDelayIncrease(_ sender: NSMenuItem) {
        // +0.5s
        guard let p = currentPlayer?.player else { return }
        let v = p.currentAudioPlaybackDelay() + 0.5
        p.setCurrentAudioPlaybackDelay(v)
    }
    
    @IBOutlet weak var audioDelayDecreaseMenuItem: NSMenuItem!
    @IBAction func audioDelayDecrease(_ sender: NSMenuItem) {
        // -0.5s
        guard let p = currentPlayer?.player else { return }
        let v = p.currentAudioPlaybackDelay() - 0.5
        p.setCurrentAudioPlaybackDelay(v)
    }
    
    @IBOutlet weak var resetAudioDelayMenuItem: NSMenuItem!
    @IBAction func resetAuidoDelay(_ sender: Any) {
        guard let p = currentPlayer?.player else { return }
        p.setCurrentAudioPlaybackDelay(0)
    }
    
    @IBOutlet weak var audioTrackMenuItem: NSMenuItem!
    
    @IBOutlet weak var stereoAudioModeMenuItem: NSMenuItem!
    
    @IBOutlet weak var visualizationsMenuItem: NSMenuItem!
    
    @IBOutlet weak var audioDeviceMenuItem: NSMenuItem!
    
    func refreshAudioDeviceList() {
        guard let menu = audioDeviceMenuItem.submenu,
              let mp = currentPlayer?.player.mediaPlayer,
              let aout = input_resource_HoldAout(mp.pointee.input.p_resource) else { return }
        let obj = VLCObject(audioOutput: aout).vlcObject()
        menu.removeAllItems()
        
        var ids: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?
        var names: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?
        let n = aout_DevicesList(aout, &ids, &names)
        
        if n == -1 {
            vlc_object_release(obj)
            return
        }
        
        var currentDevice = aout_DeviceGet(aout)
        
        (0..<Int(n)).forEach {
            guard let name = names?[$0]?.toString(),
                  let id = ids?[$0]?.toString() else { return }
            
            let item = NSMenuItem(title: name,
                                  action: #selector(toggleAudioDevice),
                                  keyEquivalent: "")
            item.target = self
            item.tag = Int(id) ?? -1
            menu.addItem(item)
            
            names?[$0]?.deallocate()
            ids?[$0]?.deallocate()
        }
        vlc_object_release(obj)
        
        guard let cd = currentDevice,
              let i = Int(cd.toString()) else {
            return
        }
        
        menu.item(withTag: i)?.state = .on
        currentDevice?.deallocate()
        names?.deallocate()
        ids?.deallocate()
        menu.autoenablesItems = true
        audioDeviceMenuItem.isEnabled = true
    }
    
    @objc func toggleAudioDevice(_ sender: NSMenuItem) {
        guard let mp = currentPlayer?.player.mediaPlayer,
              let aout = input_resource_HoldAout(mp.pointee.input.p_resource) else { return }
        
        var returnValue: Int32 = 0
        
        if sender.tag >= 0 {
            returnValue = aout_DeviceSet(aout, "\(sender.tag)".cString())
        } else {
            returnValue = aout_DeviceSet(aout, nil)
        }
        if returnValue != 0 {
            print("failed to set audio device \(sender.tag)")
        }
        
        vlc_object_release(VLCObject(audioOutput: aout).vlcObject())
        refreshAudioDeviceList()
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
    
    @IBOutlet weak var floatOnTopMenuItem: NSMenuItem!
    @IBAction func floatOnTop(_ sender: NSMenuItem) {
        guard let w = currentPlayer?.window else { return }
        let isFloating = w.level == .floating
        w.level = isFloating ? .normal : .floating
        sender.state = isFloating ? .off : .off
    }
    
    @IBOutlet weak var snapshotMenuItem: NSMenuItem!
    @IBAction func snapshot(_ sender: NSMenuItem) {
        
        guard let p = currentPlayer,
              let path = snapshotPath else { return }
        let mp = p.player.mediaPlayer
        
        var title = "unknown movie title"
        
        var titles: UnsafeMutablePointer<UnsafeMutablePointer<libvlc_title_description_t>?>?
        
        let re = libvlc_media_player_get_full_title_descriptions(mp, &titles)
        if re == -1 {
            print("libvlc_media_player_get_full_title_descriptions ERROR.")
        }
        
        let index = libvlc_media_player_get_title(mp)
        
        if let titles = titles,
           let t = titles[Int(index)] {
            title = t.pointee.psz_name.toString()
        } else {
            title = UUID().uuidString
        }
        
        let time = p.player.time.stringValue()
        
        let u = path.appendingPathComponent("\(title) - \(time).png", isDirectory: false).path
        
        libvlc_video_take_snapshot(mp, 0, u.cString(), 0, 0)
    }
    
    @IBOutlet weak var snapshotFolderMenuItem: NSMenuItem!
    @IBAction func snapshotFolder(_ sender: NSMenuItem) {
        guard let u = snapshotPath else { return }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: u.path)
    }
    
    
    @IBOutlet weak var aspectRatioMenuItem: NSMenuItem!
    
    @IBOutlet weak var cropMenuItem: NSMenuItem!
    
    @IBOutlet weak var deinterlaceMenuItem: NSMenuItem!
    
    @IBOutlet weak var videoTrackMenuItem: NSMenuItem!
    
    @IBOutlet weak var deinterlaceModeMenuItem: NSMenuItem!
    
    
// MARK: - Subtitles
    
    @IBOutlet weak var subtitlesMenu: NSMenu!
    @IBOutlet weak var subtitleTrackMenuItem: NSMenuItem!
    
    @IBOutlet weak var addSubtitleFileMenuItem: NSMenuItem!
    @IBAction func addSubtitleFile(_ sender: NSMenuItem) {
        guard let cp = currentPlayer else { return }
        let panel = Utils.shared.subtitleOpenPanel
        
        let re = panel.runModal()
        if re == .OK, let u = panel.url?.absoluteString {
            cp.player.loadSubtitle(u)
        }
    }
    
    @IBAction func disableSubtitle(_ sender: NSMenuItem) {
        currentPlayer?.player.disableSubtitle()
    }
    
    @IBAction func subtitleItemAction(_ sender: NSMenuItem) {
        currentPlayer?.player.setSubtitleIndex(sender.tag)
    }
    
    @IBOutlet weak var subtitleDelayMenuItem: NSMenuItem!
    
    @IBOutlet weak var subtitleDelayIncreaseMenuItem: NSMenuItem!
    @IBAction func subtitleDelayIncrease(_ sender: NSMenuItem) {
        // +0.5s
        guard let p = currentPlayer?.player else { return }
        let v = p.currentVideoSubTitleDelay() + 0.5
        p.setCurrentVideoSubTitleDelay(v)
    }
    
    @IBOutlet weak var subtitleDelayDecreaseMenuItem: NSMenuItem!
    @IBAction func subtitleDelayDecrease(_ sender: NSMenuItem) {
        // -0.5s
        guard let p = currentPlayer?.player else { return }
        let v = p.currentVideoSubTitleDelay() - 0.5
        p.setCurrentVideoSubTitleDelay(v)
    }
    
    @IBOutlet weak var resetSubtitleDelayMenuItem: NSMenuItem!
    @IBAction func resetSubtitleDelay(_ sender: NSMenuItem) {
        guard let p = currentPlayer?.player else { return }
        p.setCurrentVideoSubTitleDelay(0)
    }
    
    @IBOutlet weak var subtitleScaleMenuItem: NSMenuItem!
    
    @IBOutlet weak var subtitleScaleIncreaseMenuItem: NSMenuItem!
    @IBAction func subtitleScaleIncrease(_ sender: NSMenuItem) {
        guard let p = currentPlayer else { return }
//        p.assRenderer.libass.setFontScale(2)
    }
    
    @IBOutlet weak var subtitleScaleDecreaseMenuItem: NSMenuItem!
    @IBAction func subtitleScaleDecrease(_ sender: NSMenuItem) {
    }
    
    @IBOutlet weak var resetSubtitleScaleMenuItem: NSMenuItem!
    @IBAction func resetSubtitleScale(_ sender: NSMenuItem) {
    }
    
// MARK: - Window
    
    @IBOutlet weak var infoMenuItem: NSMenuItem!
    @IBAction func info(_ sender: NSMenuItem) {
        let utils = Utils.shared
        utils.vlcInfos.updateInfos()
        utils.vlcInfos.start()
        utils.infoPanel.makeKeyAndOrderFront(sender)
        utils.infoPanel.center()
    }
}
