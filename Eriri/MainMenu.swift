//
//  MainMenu.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/27.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa

class MainMenu: NSObject, NSMenuItemValidation, NSMenuDelegate {
    
    let aspectRatioValues: [(title: String, value: String)] =
        [("16:9",   "16:9"),
         ("4:3",    "4:3"),
         ("1:1",    "1:1"),
         ("16:10",  "16:10"),
         ("2.21:1", "221:100"),
         ("2.35:1", "235:100"),
         ("2.39:1", "239:100"),
         ("5:4",    "5:4")]
    
    let cropValues: [(title: String, value: String)] =
        [("16:10",  "16:10"),
         ("16:9",   "16:9"),
         ("4:3",    "4:3"),
         ("1.85:1", "185:100"),
         ("2.21:1", "221:100"),
         ("2.35:1", "235:100"),
         ("2.39:1", "239:100"),
         ("5:3",    "5:3"),
         ("5:4",    "5:4"),
         ("1:1",    "1:1")]
    
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
        switch menu {
        case subtitleListMenu:
            menu.removeAllItems()
            let subtitles = p.player.subtitles()
            let current = subtitles.currentIndex
            let noneItem = NSMenuItem()
            noneItem.state = current == -1 ? .on : .off
            noneItem.title = "Disable"
            noneItem.target = self
            noneItem.action = #selector(self.disableSubtitle(_:))
            menu.addItem(noneItem)
            subtitles.descriptions.forEach {
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
        case subtitlesMenu:
            let v = p.player.currentVideoSubTitleDelay()
            
            subtitleDelayMenuItem.title = "Subtitle Delay: \(v)s"
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
            
            vlc_mutex_lock(&mp.pointee.input.lock)
            let inputThread = mp.pointee.input.p_thread
            vlc_mutex_unlock(&mp.pointee.input.lock)
            
            if let it = inputThread {
                let obj = VLCObject(inputThread: it).vlcObject()
                setupVarMenuItem(audioTrackMenuItem,
                                 target: obj,
                                 variable: "audio-es",
                                 selector: #selector(toggleVar))
            }
            
        case aspectRatioMenu:
            if menu.items.count == 0 {
                func item(_ title: String) -> NSMenuItem {
                    let item = NSMenuItem()
                    item.title = title
                    item.target = self
                    item.action = #selector(self.setAspectRatio(_:))
                    return item
                }
                
                menu.addItem(item("Default"))
                menu.addItem(.separator())
                aspectRatioValues.forEach {
                    menu.addItem(item($0.title))
                }
            }
            
            let ar = libvlc_video_get_aspect_ratio(p.player.mediaPlayer)
            guard let arStr = ar?.toString(),
                  let value = aspectRatioValues.first (where: { $0.value == arStr }) else {
                menu.items.forEach {
                    $0.state = .off
                }
                menu.items.first?.state = .on
                return
            }
            
            menu.items.forEach {
                $0.state = $0.title == value.title ? .on : .off
            }
            
        case cropMenu:
            if menu.items.count == 0 {
                func item(_ title: String) -> NSMenuItem {
                    let item = NSMenuItem()
                    item.title = title
                    item.target = self
                    item.action = #selector(self.setCrop(_:))
                    return item
                }
                
                menu.addItem(item("Default"))
                menu.addItem(.separator())
                cropValues.forEach {
                    menu.addItem(item($0.title))
                }
            }
            
            let cg = libvlc_video_get_crop_geometry(p.player.mediaPlayer)
            guard let cgStr = cg?.toString(),
                  let value = cropValues.first (where: { $0.value == cgStr }) else {
                
                menu.items.forEach {
                    $0.state = .off
                }
                menu.items.first?.state = .on
                return
            }
            
            menu.items.forEach {
                $0.state = $0.title == value.title ? .on : .off
            }
            
        case deinterlaceMenu:
            let disable = "Disable"
            if menu.items.count == 0 {
                func item(_ title: String) -> NSMenuItem {
                    let item = NSMenuItem()
                    item.title = title
                    item.target = self
                    item.action = #selector(self.setDeinterlace(_:))
                    return item
                }
                
                VLCMediaPlayer.DeinterlaceMode.allCases.forEach {
                    if $0 == .disable {
                        menu.addItem(item(disable))
                        menu.addItem(.separator())
                    } else {
                        menu.addItem(item($0.rawValue))
                    }
                }
            }
            
            var deinterlace = p.player.deinterlace.rawValue
            
            if deinterlace == "" {
                deinterlace = disable
            }
            
            menu.items.forEach {
                $0.state = $0.title == deinterlace ? .on : .off
            }
        case videoTrackMenu:
            
            func item(_ title: String) -> NSMenuItem {
                let item = NSMenuItem()
                item.title = title
                item.target = self
                item.action = #selector(self.setVideoTrack(_:))
                return item
            }
            
            menu.removeAllItems()
            let disableItem = item("Disable")
            disableItem.tag = -1
            menu.addItem(disableItem)
            menu.addItem(.separator())
            
            let tracks = p.player.getVideoTracks()
            tracks.forEach {
                let i = item($0.name)
                i.state = $0.selected ? .on : .off
                i.tag = Int($0.id) ?? -1
                menu.addItem(i)
            }
            
            if tracks.filter({ $0.selected }).count == 0 {
                disableItem.state = .on
            }
        case videoMenu:
            floatOnTopMenuItem.state = p.window.level == .floating ? .on : .off
            
            
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
            
        case halfSizeMenuItem, normalSizeMenuItem, doubleSizeMenuItem, fitToScreenMenuItem, increaseSizeMenuItem, decreaseSizeMenuItem, floatOnTopMenuItem, snapshotMenuItem:
            
            guard let player = currentPlayer else { return false }
            return true
            
        case addSubtitleFileMenuItem, subtitlesMenuItem, subtitleDelayDecreaseMenuItem, subtitleDelayIncreaseMenuItem,
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
        case _ where menuItem.menu == cropMenu:
            return true
        case _ where menuItem.menu == aspectRatioMenu:
            return true
        case _ where menuItem.menu == deinterlaceMenu:
            return true
        case _ where menuItem.menu == videoTrackMenu:
            return true
        case _ where menuItem.menu == subtitleListMenu:
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
                
                if strcmp(val.psz_string, valV.psz_string) == 0
                    && (type & VLC_VAR_ISCOMMAND) == 0 {
                    item.state = .on
                }
            case VLC_VAR_INTEGER:
                item.title = textV.psz_string != nil ? textV.psz_string.toString() : "\(textV.i_int)"
                item.action = callback
                item.target = self
                let data = VLCAutoGeneratedMenuContent(variable, of: object, and: valV, of: Int(type))
                item.representedObject = data
                menu.addItem(item)
                
                if valV.i_int == val.i_int
                    && (type & VLC_VAR_ISCOMMAND) == 0 {
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
        
        let time = p.player.currentTime().stringValue()
        
        let u = path.appendingPathComponent("\(title) - \(time).png", isDirectory: false).path
        
        libvlc_video_take_snapshot(mp, 0, u.cString(), 0, 0)
    }
    
    @IBOutlet weak var snapshotFolderMenuItem: NSMenuItem!
    @IBAction func snapshotFolder(_ sender: NSMenuItem) {
        guard let u = snapshotPath else { return }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: u.path)
    }
    
    @IBOutlet weak var aspectRatioMenu: NSMenu!
    
    @IBAction func setAspectRatio(_ sender: NSMenuItem) {
        guard let p = currentPlayer?.player.mediaPlayer else { return }
        
        if let v = aspectRatioValues.first(where: { $0.title == sender.title })?.value,
           let cv = v.cString() {
            libvlc_video_set_aspect_ratio(p, cv)
        } else {
            libvlc_video_set_aspect_ratio(p, nil)
        }
        
        
        // Update Content Size?
    }
    
    @IBOutlet weak var cropMenu: NSMenu!
    
    @IBAction func setCrop(_ sender: NSMenuItem) {
        guard let p = currentPlayer?.player.mediaPlayer else { return }
        
        
        if let v = cropValues.first(where: { $0.title == sender.title })?.value,
           let cv = v.cString() {
            libvlc_video_set_crop_geometry(p, cv)
        } else {
            libvlc_video_set_crop_geometry(p, nil)
        }
        
        
        // Update Content Size?
        
    }
    
    @IBOutlet weak var deinterlaceMenu: NSMenu!
    
    @IBAction func setDeinterlace(_ sender: NSMenuItem) {
        guard let p = currentPlayer?.player else { return }
        p.deinterlace = VLCMediaPlayer.DeinterlaceMode(rawValue: sender.title) ?? .disable
    }
    
    @IBOutlet weak var videoTrackMenu: NSMenu!
    
    @IBAction func setVideoTrack(_ sender: NSMenuItem) {
        guard let p = currentPlayer?.player else { return }
        
        p.setVideoTrack("\(sender.tag)")
        
    }
    
// MARK: - Subtitles
    
    @IBOutlet weak var subtitlesMenu: NSMenu!
    @IBOutlet weak var subtitleListMenu: NSMenu!
    @IBOutlet weak var subtitlesMenuItem: NSMenuItem!
    
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
