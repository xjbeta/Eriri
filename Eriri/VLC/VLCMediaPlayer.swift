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
    
    private var mediaPlayer: OpaquePointer?
    private var eventManager: OpaquePointer?
    private var eventsAttached = false
    
    
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
    
    func initEventAttachs() {
        guard !eventsAttached,
            let mp = mediaPlayer else { return }
        eventManager = libvlc_media_player_event_manager(mp)
        
        guard let em = eventManager else { return }
        
        attachEvents.forEach {
            addEventAttach($0, to: em)
        }
        eventsAttached = true
    }
    
    func deinitEventAttachs() {
        
        
//        libvlc_event_detach
    }
    
    func nextChapter() {
        guard let mp = mediaPlayer else { return }
        libvlc_media_player_next_chapter(mp)
    }
    
    func previousChapter() {
        guard let mp = mediaPlayer else { return }
        libvlc_media_player_previous_chapter(mp)
    }
    
    func tracksInformation() {
        guard let mp = mediaPlayer else { return }
        
//        var tracksInfo: UnsafeMutablePointer<UnsafeMutablePointer<UnsafeMutablePointer<libvlc_media_track_t>?>?>? = nil
//
        var tracksInfo: libvlc_media_track_t

        

//        libvlc_media_tracks_get(mp, )
//
//
//        print(tracksInfo)
//
    }
    
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


private extension VLCMediaPlayer {
    
    func addEventAttach(_ event: libvlc_event_e, to eventManager: OpaquePointer) {
        let s = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    
        
        libvlc_event_attach(eventManager, libvlc_event_type_t(event.rawValue), { new, s in
            

            guard let n = new,
                let ss = s else { return }
            let event = n.pointee
            let mp = Unmanaged<VLCMediaPlayer>.fromOpaque(ss).takeUnretainedValue()
            guard let d = mp.delegate else { return }
            
            let rValue = event.type
            let type = libvlc_event_type_t(rValue)
            
//            if let name = libvlc_event_type_name(type) {
//                let nameStr = String(cString: name)
//                print("Event Attach: \(nameStr)")
//            }
            
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
                    d.mediaPlayerStateChanged(.buffering)
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
                    d.mediaPlayerLengthChanged(VLCTime(with: time))
                    
                case libvlc_MediaPlayerAudioVolume:
                    let v = event.u.media_player_audio_volume.volume
                    d.mediaPlayerAudioVolume(Int(v * Float(mp.volumeMAX)))
                default:
                    break
                }
            }
        }, s)
    }
    
}

