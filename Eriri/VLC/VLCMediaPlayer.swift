//
//  VLCMediaPlayer.swift
//  Eriri
//
//  Created by xjbeta on 2020/2/8.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa

enum VLCMediaPlayerState: Int {
    case stopped
    case opening
    case buffering
    case ended
    case error
    case playing
    case paused
    case esAdded
}

protocol VLCMediaPlayerDelegate {
    func mediaPlayerTimeChanged(_ time: VLCTime)
    func mediaPlayerPositionChanged(_ value: Float)
    func mediaPlayerStateChanged(_ state: VLCMediaPlayerState)
    func mediaPlayerLengthChanged(_ time: VLCTime)
    func mediaPlayerAudioVolume(_ value: Int)
    
    
//    func mediaPlayerMediaChanged()
//    func mediaPlayerTitleChanged()
//    func mediaPlayerChapterChanged()
//
//    func mediaPlayerSnapshot()
//    func mediaPlayerRecordChanged()
}

class VLCMediaPlayer: NSObject {
    
    let volumeMAX = 100
    let volumeMIN = 0
    
    var mediaPlayer: OpaquePointer?
    var eventManager: OpaquePointer?
    var eventsAttached = false
    
    let attachEvents: [libvlc_event_e] = [
        // State
        libvlc_MediaPlayerOpening,
        libvlc_MediaPlayerPlaying,
        libvlc_MediaPlayerPaused,
        libvlc_MediaPlayerBuffering,
        libvlc_MediaPlayerStopped,
        libvlc_MediaPlayerEndReached,
        libvlc_MediaPlayerESAdded,
        libvlc_MediaPlayerEncounteredError,
        
        // Player info
        libvlc_MediaPlayerPositionChanged,
        libvlc_MediaPlayerTimeChanged,
        libvlc_MediaPlayerLengthChanged,
        libvlc_MediaPlayerAudioVolume,
        
        libvlc_MediaPlayerForward,
        libvlc_MediaPlayerBackward,

//        libvlc_MediaPlayerTitleChanged,
        libvlc_MediaPlayerMuted,
        libvlc_MediaPlayerUnmuted
    ]
    
    var videoSize: CGSize {
        get {
            guard let mp = mediaPlayer else { return .zero }
            var width: UInt32 = 0
            var height: UInt32 = 0
            
            guard libvlc_video_get_size(mp, 0, &width, &height) == 0 else {
                return .zero
            }
            return .init(width: CGFloat(width),
                         height: CGFloat(height))
        }
    }
    
    var remainingTime: VLCTime {
        get {
            //        libvlc_media_player_get
            let time = VLCTime(with: 0)
            return time
        }
    }
    
    var position: Float {
        get {
            guard let mp = mediaPlayer else { return 0 }
            return libvlc_media_player_get_position(mp)
        }
        set {
            guard let mp = mediaPlayer else { return }
            if libvlc_media_player_is_seekable(mp) == 1 {
                libvlc_media_player_set_position(mp, newValue)
            }
        }
    }
    
    var volume: Int {
        get {
            guard let mp = mediaPlayer else { return 0 }
            let v = libvlc_audio_get_volume(mp)
            return Int(v)
        }
        set {
            guard let mp = mediaPlayer else { return }
            var v = newValue
            if v > volumeMAX {
                v = volumeMAX
            }
            if v < volumeMIN {
                v = volumeMIN
            }
            libvlc_audio_set_volume(mp, Int32(v))
        }
    }
    
    var mute: Bool {
        get {
            guard let mp = mediaPlayer else { return true }
            return libvlc_audio_get_mute(mp) == 1
        }
        set {
            guard let mp = mediaPlayer else { return }
            libvlc_audio_set_mute(mp, Int32(newValue ? 1 : 0))
        }
    }
    
    var delegate: VLCMediaPlayerDelegate? {
        didSet {
            guard let mp = mediaPlayer else { return }
            eventManager = libvlc_media_player_event_manager(mp)
            self.initEventAttachs()
        }
    }
    
    let libVLCBackgroundQueue = DispatchQueue(label: "libvlcQueue")
    
    private var _videoView: NSView?
    var videoView: NSView? {
        set {
            _videoView = newValue
            
            guard let p = mediaPlayer,
                let vv = _videoView else { return }
            let v = UnsafeMutableRawPointer(Unmanaged.passUnretained(vv).toOpaque())
            
            libVLCBackgroundQueue.async {
                libvlc_media_player_set_nsobject(p, v)
            }
        }
        get {
            return _videoView
        }
    }
    
    override init() {
        super.init()
        guard let instance = VLCLibrary.shared.instance else { return }
        mediaPlayer = libvlc_media_player_new(instance)
    }
    
    func setMedia(_ url: String) {
        guard let instance = VLCLibrary.shared.instance else { return }
        let media = libvlc_media_new_location(instance, url)
        guard let mp = mediaPlayer, let m = media else { return }
        libvlc_media_player_set_media(mp, m)
    }
    
    func togglePlay() {
        guard let mp = mediaPlayer else { return }
        libvlc_media_player_pause(mp)
    }
    
    func toggleMute() {
        guard let mp = mediaPlayer else { return }
        libvlc_audio_toggle_mute(mp)
    }
    
    func isPlaying() -> Bool {
        guard let mp = mediaPlayer else { return false }
        return libvlc_media_player_is_playing(mp) == 1
        
    }
    
    func play() {
        guard let mp = mediaPlayer else { return }
        libVLCBackgroundQueue.async {
            libvlc_media_player_play(mp)
        }
    }
    
    func pause() {
        guard let mp = mediaPlayer else { return }
        libVLCBackgroundQueue.async {
            libvlc_media_player_set_pause(mp, 1)
        }
    }
    
    
    func stop() {
        guard let mp = mediaPlayer else { return }
        libvlc_media_player_stop(mp)
    }
    
    func seek(_ seconds: Int) {
        if isSeekable() {
            let interval = Int64(seconds) * 1000
            let time = currentTime()
            time.value = Int64(time.value) + interval
            setTime(time)
        }
    }
    
    func currentTime() -> VLCTime {
        let time = VLCTime(with: 0)
        guard let mp = mediaPlayer else { return time }
        time.value = libvlc_media_player_get_time(mp)
        return time
    }
    
    func setTime(_ time: VLCTime) {
        guard let mp = mediaPlayer else { return }
        libvlc_media_player_set_time(mp, libvlc_time_t(time.value))
    }
    
    func isSeekable() -> Bool {
        guard let mp = mediaPlayer else { return false }
        return libvlc_media_player_is_seekable(mp) == 1
    }
    
    
    func nextChapter() {
        guard let mp = mediaPlayer else { return }
        libvlc_media_player_next_chapter(mp)
    }
    
    func previousChapter() {
        guard let mp = mediaPlayer else { return }
        libvlc_media_player_previous_chapter(mp)
    }
    
    // MARK: - Subtitles
    
    func setSubtitleIndex(_ index: Int) {
        guard let mp = mediaPlayer else { return }
        libvlc_video_set_spu(mp, Int32(index))
    }
    
    func subtitles() -> VLCTrackDescription {
        var re = VLCTrackDescription()
        guard let mp = mediaPlayer else { return re }
        let count = libvlc_video_get_spu_count(mp)
        let currentIndex = libvlc_video_get_spu(mp)
        guard let list = libvlc_video_get_spu_description(mp) else {
            return re
        }

        re = .init(description: list.pointee, count: count, currentIndex: currentIndex)
        
        libvlc_track_description_list_release(list)
        return re
    }
    
    func loadSubtitle(_ url: String) {
        guard let mp = mediaPlayer else { return }
        libvlc_media_player_add_slave(mp, libvlc_media_slave_type_subtitle, NSString(string: url).utf8String, true)
    }
    
    // MARK: - Audio
    
    func setAudioTrackIndex(_ index: Int) {
        guard let mp = mediaPlayer else { return }
        libvlc_audio_set_track(mp, Int32(index))
    }
    
    func audioTracks() -> VLCTrackDescription {
        var re = VLCTrackDescription()
        guard let mp = mediaPlayer else { return re }
        let count = libvlc_audio_get_track_count(mp)
        let currentIndex = libvlc_audio_get_track(mp)
        guard let list = libvlc_audio_get_track_description(mp) else {
            return re
        }
        
        re = .init(description: list.pointee, count: count, currentIndex: currentIndex)
        
        libvlc_track_description_list_release(list)
        return re
    }
}

