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
    func mediaPlayerBuffing(_ newCache: Float)
    func mediaPlayerLengthChanged(_ time: VLCTime)
    func mediaPlayerAudioVolume(_ value: Int)
    func mediaPlayerAudioMuted(_ muted: Bool)
    
    
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
    
    var mediaPlayer: UnsafeMutablePointer<libvlc_media_player_t>?
    var player: UnsafeMutablePointer<vlc_player_t>?
    
    
    var eventManager: UnsafeMutablePointer<libvlc_event_manager_t>?
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
        libvlc_MediaPlayerNothingSpecial,
        
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
    
    var eventCallBack: libvlc_callback_t = { new, s in
        
        guard let n = new,
            let ss = s else { return }
        let event = n.pointee
        let mp = Unmanaged<VLCMediaPlayer>.fromOpaque(ss).takeUnretainedValue()
        guard let d = mp.delegate else { return }
        
        let rValue = event.type
        let type = libvlc_event_type_t(rValue)
        
        DispatchQueue.main.async {
            switch libvlc_event_e(UInt32(type)) {
            // State
            case libvlc_MediaPlayerOpening:
                d.mediaPlayerStateChanged(.opening)
            case libvlc_MediaPlayerPlaying:
                d.mediaPlayerStateChanged(.playing)
            case libvlc_MediaPlayerPaused:
                d.mediaPlayerStateChanged(.paused)
            case libvlc_MediaPlayerBuffering:
                let newCache = event.u.media_player_buffering.new_cache
                d.mediaPlayerBuffing(newCache)
            case libvlc_MediaPlayerStopped:
                d.mediaPlayerStateChanged(.stopped)
            case libvlc_MediaPlayerEndReached:
                d.mediaPlayerStateChanged(.ended)
            case libvlc_MediaPlayerESAdded:
                d.mediaPlayerStateChanged(.esAdded)
            case libvlc_MediaPlayerEncounteredError:
                d.mediaPlayerStateChanged(.error)
                
            // Player info
            case libvlc_MediaPlayerPositionChanged:
                let f = event.u.media_player_position_changed.new_position
                d.mediaPlayerPositionChanged(f)
            case libvlc_MediaPlayerTimeChanged:
                let time = event.u.media_player_time_changed.new_time
                d.mediaPlayerTimeChanged(VLCTime(with: time))
                
            case libvlc_MediaPlayerLengthChanged:
                let time = event.u.media_player_length_changed.new_length
                let t = VLCTime(with: time)
                mp.mediaLength = t
                d.mediaPlayerLengthChanged(t)
                
            case libvlc_MediaPlayerAudioVolume:
                let v = event.u.media_player_audio_volume.volume
                
//                let volume = Int(v * Float(mp.volumeMAX))
                let volume = lroundf(v * 100)
                d.mediaPlayerAudioVolume(volume)
            case libvlc_MediaPlayerMuted:
                d.mediaPlayerAudioMuted(true)
            case libvlc_MediaPlayerUnmuted:
                d.mediaPlayerAudioMuted(false)
            default:
                break
            }
        }
    }
    
    
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
    
    var mediaLength = VLCTime(with: 0)
    
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
    }
    
    func setPosition(_ value: Float,
                     _ fast: Bool) {
        guard let mp = mediaPlayer else { return }
        
        let v = Int64(Float(mediaLength.value) * value)
        delegate?.mediaPlayerTimeChanged(VLCTime(with: v))
        if libvlc_media_player_is_seekable(mp) {
            libvlc_media_player_set_position(mp, value, fast)
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
    
    private var _videoView: NSView?
    var videoView: NSView? {
        set {
            _videoView = newValue
            
            guard let p = mediaPlayer,
                let vv = _videoView else { return }
            let v = UnsafeMutableRawPointer(Unmanaged.passUnretained(vv).toOpaque())
            
            libvlc_media_player_set_nsobject(p, v)
        }
        get {
            return _videoView
        }
    }
    
    
    override init() {
        super.init()
        let instance = VLCLibrary.shared.instance
        mediaPlayer = libvlc_media_player_new(instance)
        player = mediaPlayer?.pointee.player
    }
    
    func setMedia(_ url: String) {
        let instance = VLCLibrary.shared.instance
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
        return libvlc_media_player_is_playing(mp)
    }
    
    func play() {
        guard let mp = mediaPlayer else { return }
        libvlc_media_player_play(mp)
    }
    
    func pause() {
        guard let mp = mediaPlayer else { return }
        libvlc_media_player_set_pause(mp, 1)
    }
    
    
    func stop() {
        guard let mp = mediaPlayer else { return }
        libvlc_media_player_stop_async(mp)
    }
    
    func seek(_ seconds: Int, _ fast: Bool) {
        if isSeekable() {
            let interval = Int64(seconds) * 1000
            let time = currentTime()
            time.value = Int64(time.value) + interval
            setTime(time, fast)
        }
    }
    
    func currentTime() -> VLCTime {
        let time = VLCTime(with: 0)
        guard let mp = mediaPlayer else { return time }
        time.value = libvlc_media_player_get_time(mp)
        return time
    }
    
    func setTime(_ time: VLCTime, _ fast: Bool) {
        guard let mp = mediaPlayer else { return }
        libvlc_media_player_set_time(mp, libvlc_time_t(time.value), fast)
    }
    
    func isSeekable() -> Bool {
        guard let mp = mediaPlayer else { return false }
        return libvlc_media_player_is_seekable(mp)
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
    
    func disableSubtitle() {
        guard let p = player else { return }
        vlc_player_Lock(p)
        vlc_player_UnselectTrackCategory(p, SPU_ES)
        vlc_player_Unlock(p)
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
    
    func currentVideoSubTitleDelay() -> Float {
        guard let mp = mediaPlayer else { return 0 }
        return Float(libvlc_video_get_spu_delay(mp)) / 1000000
    }
    
    func setCurrentVideoSubTitleDelay(_ value: Float) {
        guard let mp = mediaPlayer else { return }
        libvlc_video_set_spu_delay(mp, Int64(value * 1000000))
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
    
    func currentAudioPlaybackDelay() -> Float {
        guard let mp = mediaPlayer else { return 0 }
        return Float(libvlc_audio_get_delay(mp)) / 1000000
    }
    
    func setCurrentAudioPlaybackDelay(_ value: Float) {
        guard let mp = mediaPlayer else { return }
        libvlc_audio_set_delay(mp, Int64(value * 1000000))
    }
}

