//
//  VLCMediaPlayer.swift
//  Eriri
//
//  Created by xjbeta on 2020/2/8.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa

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
    
    var mediaPlayer: UnsafeMutablePointer<libvlc_media_player_t>
    var player: UnsafeMutablePointer<vlc_player_t>
    
    var eventManager: UnsafeMutablePointer<libvlc_event_manager_t>!
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
            let e = libvlc_event_e(UInt32(type))
            switch e {
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
//                d.mediaPlayerStateChanged(.esAdded)
                break
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
            var width: UInt32 = 0
            var height: UInt32 = 0
            
            guard libvlc_video_get_size(mediaPlayer, 0, &width, &height) == 0 else {
                return .init(width: 800, height: 450)
            }
            return .init(width: CGFloat(width / 2),
                         height: CGFloat(height / 2))
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
            return libvlc_media_player_get_position(mediaPlayer)
        }
    }
    
    func setPosition(_ value: Float,
                     _ fast: Bool) {
        let v = Int64(Float(mediaLength.value) * value)
        delegate?.mediaPlayerTimeChanged(VLCTime(with: v))
        if libvlc_media_player_is_seekable(mediaPlayer) {
            libvlc_media_player_set_position(mediaPlayer, value, fast)
        }
    }
    
    var volume: Int {
        get {
            let v = libvlc_audio_get_volume(mediaPlayer)
            return Int(v)
        }
        set {
            var v = newValue
            if v > volumeMAX {
                v = volumeMAX
            }
            if v < volumeMIN {
                v = volumeMIN
            }
            libvlc_audio_set_volume(mediaPlayer, Int32(v))
        }
    }
    
    var rate: Float {
        get {
            return libvlc_media_player_get_rate(mediaPlayer)
        }
        set {
            libvlc_media_player_set_rate(mediaPlayer, newValue)
        }
    }
    
    var mute: Bool {
        get {
            return libvlc_audio_get_mute(mediaPlayer) == 1
        }
        set {
            libvlc_audio_set_mute(mediaPlayer, Int32(newValue ? 1 : 0))
        }
    }
    
    var delegate: VLCMediaPlayerDelegate? {
        didSet {
            self.initEventAttachs()
        }
    }
    
    private var _videoView: NSView?
    var videoView: NSView? {
        set {
            _videoView = newValue
            
            guard let vv = _videoView else { return }
            let v = UnsafeMutableRawPointer(Unmanaged.passUnretained(vv).toOpaque())
            
            libvlc_media_player_set_nsobject(mediaPlayer, v)
        }
        get {
            return _videoView
        }
    }
    
    
    override init() {
        let instance = VLCLibrary.shared.instance
        mediaPlayer = libvlc_media_player_new(instance)
        player = mediaPlayer.pointee.player
        eventManager = libvlc_media_player_event_manager(mediaPlayer)
        
        super.init()
        libvlc_set_user_agent(instance, "eriri".cString(), "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Safari/605.1.15".cString())
    }
    
    func setMedia(_ url: String) {
        let instance = VLCLibrary.shared.instance
        let media = libvlc_media_new_location(instance, url)
        libvlc_media_parse(media)
        let status = libvlc_media_get_parsed_status(media)
        print("parsed_status", status)
        switch status {
        case libvlc_media_parsed_status_skipped:
            break
        case libvlc_media_parsed_status_failed:
            break
        case libvlc_media_parsed_status_timeout:
            break
        case libvlc_media_parsed_status_done:
            break
        default:
            break
        }
        
        let mType = libvlc_media_get_type(media)
        let type = VLCMediaType(type: mType)
        
        switch type {
        case .file:
            libvlc_media_player_set_media(mediaPlayer, media)
        default:
            assert(false, "VLCMediaType: \(type)")
        }
    }
    
    func togglePlay() {
        libvlc_media_player_pause(mediaPlayer)
    }
    
    func toggleMute() {
        libvlc_audio_toggle_mute(mediaPlayer)
    }
    
    func isPlaying() -> Bool {
        return libvlc_media_player_is_playing(mediaPlayer)
    }
    
    func play() {
        libvlc_media_player_play(mediaPlayer)
    }
    
    func stop() {
        libvlc_media_player_stop_async(mediaPlayer)
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
        let t = libvlc_media_player_get_time(mediaPlayer)
        return VLCTime(with: t)
    }
    
    func setTime(_ time: VLCTime, _ fast: Bool) {
        libvlc_media_player_set_time(mediaPlayer, libvlc_time_t(time.value), fast)
    }
    
    func isSeekable() -> Bool {
        return libvlc_media_player_is_seekable(mediaPlayer)
    }
    
    
    func nextChapter() {
        libvlc_media_player_next_chapter(mediaPlayer)
    }
    
    func previousChapter() {
        libvlc_media_player_previous_chapter(mediaPlayer)
    }
    
    func currentMedia() -> UnsafeMutablePointer<libvlc_media_t>? {
        let media = libvlc_media_player_get_media(mediaPlayer)
        return media
    }
    
    func title() -> String {
        let media = currentMedia()
        let title = libvlc_media_get_meta(media, libvlc_meta_Title).toString()
        return title
    }
    
    func path() -> String {
        let media = currentMedia()
        guard let u = media?.pointee.p_input_item.pointee.psz_uri else { return "" }
        return String(cString: u)
    }
    
    func state() -> VLCMediaPlayerState {
        let s = libvlc_media_player_get_state(mediaPlayer)
        
        return VLCMediaPlayerState(state: s)
    }
    
    
    // MARK: - Subtitles
    
    func setSubtitleIndex(_ index: Int) {
        libvlc_video_set_spu(mediaPlayer, Int32(index))
    }
    
    func disableSubtitle() {
        vlc_player_Lock(player)
        vlc_player_UnselectTrackCategory(player, SPU_ES)
        vlc_player_Unlock(player)
    }
    
    func subtitles() -> VLCTrackDescription {
        var re = VLCTrackDescription()
        let count = libvlc_video_get_spu_count(mediaPlayer)
        let currentIndex = libvlc_video_get_spu(mediaPlayer)
        guard let list = libvlc_video_get_spu_description(mediaPlayer) else {
            return re
        }

        re = .init(description: list.pointee, count: count, currentIndex: currentIndex)
        
        libvlc_track_description_list_release(list)
        return re
    }
    
    func loadSubtitle(_ url: String) {
        libvlc_media_player_add_slave(
            mediaPlayer,
            libvlc_media_slave_type_subtitle,
            url.cString(),
            true)
    }
    
    func currentVideoSubTitleDelay() -> Float {
        return Float(libvlc_video_get_spu_delay(mediaPlayer)) / 1000000
    }
    
    func setCurrentVideoSubTitleDelay(_ value: Float) {
        libvlc_video_set_spu_delay(mediaPlayer, Int64(value * 1000000))
    }
    
    // MARK: - Audio
    
    func setAudioTrackIndex(_ index: Int) {
        libvlc_audio_set_track(mediaPlayer, Int32(index))
    }
    
    func audioTracks() -> VLCTrackDescription {
        var re = VLCTrackDescription()
        let count = libvlc_audio_get_track_count(mediaPlayer)
        let currentIndex = libvlc_audio_get_track(mediaPlayer)
        guard let list = libvlc_audio_get_track_description(mediaPlayer) else {
            return re
        }
        
        re = .init(description: list.pointee, count: count, currentIndex: currentIndex)
        
        libvlc_track_description_list_release(list)
        return re
    }
    
    func currentAudioPlaybackDelay() -> Float {
        return Float(libvlc_audio_get_delay(mediaPlayer)) / 1000000
    }
    
    func setCurrentAudioPlaybackDelay(_ value: Float) {
        libvlc_audio_set_delay(mediaPlayer, Int64(value * 1000000))
    }

    enum DeinterlaceMode: String, CaseIterable {
        case disable = ""
        
        case blend,
             bob,
             discard,
             linear,
             mean,
             x,
             yadif,
             yadif2x,
             phosphor,
             ivtc
    }
    
    var deinterlace: DeinterlaceMode {
        get {
            let obj = VLCHack().vlc_object(mediaPlayer)
            
            let d = var_GetInteger(obj, "deinterlace".cString())
            if d == 0 {
                return .disable
            } else {
                let dMode = var_GetNonEmptyString(obj, "deinterlace-mode".cString()).toString()
                return DeinterlaceMode(rawValue: dMode) ?? .disable
            }
        }
        set {
            libvlc_video_set_deinterlace(mediaPlayer,
                                         newValue.rawValue)
        }
    }
    
}

