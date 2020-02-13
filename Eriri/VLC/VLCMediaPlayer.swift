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
    
    
    func nextChapter() {
        guard let mp = mediaPlayer else { return }
        libvlc_media_player_next_chapter(mp)
    }
    
    func previousChapter() {
        guard let mp = mediaPlayer else { return }
        libvlc_media_player_previous_chapter(mp)
    }
    
    enum TrackType: String {
        case video = "Video"
        case audio = "Audio"
        case text = "Text"
        case unknown = "Unknown"
    }
    
    enum TrackInfoKey : String {
        case format        = "Format"
        case codec         = "Codec"
        case size          = "Size"
        case bitRate       = "Bit Rate"
        case fps           = "FPS"
        case language      = "Language"
        case decodedFormat = "Decoded Format"
        case colorSpace    = "Color Space"
        case channels      = "Channels"
        case simpleRate    = "Simple Rate"
        case bitsPreSample = "Bits Pre Sample"
        case sampleAspectRatio = "Sample Aspect Ratio"
        case sampleRate = "Sample Rate"
        case encoding = "Encoding"
    }
    
    enum AudioChannel: Int {
        case error   = -1
        case stereo  =  1
        case rStereo =  2
        case left    =  3
        case right   =  4
        case dolbys  =  5

        func string() -> String {
            switch self {
            case .error:
                return "Error"
            case .stereo:
                return "Stereo"
            case .rStereo:
                return "RStereo"
            case .left:
                return "Left"
            case .right:
                return "Right"
            case .dolbys:
                return "Dolbys"
            default:
                return ""
            }
        }
    }
    
    func tracksInformation() -> [VLCInfomation] {
        var re = [VLCInfomation]()
        guard let mp = mediaPlayer,
            let m = libvlc_media_player_get_media(mp) else { return re }
//        libvlc_media_get_parsed_status(m)
        
        libvlc_media_parse_with_options(m, libvlc_media_parse_local, 0)
        
        var tracksInfo : UnsafeMutablePointer<UnsafeMutablePointer<libvlc_media_track_t>?>? = nil
        
        let count = libvlc_media_tracks_get(m, &tracksInfo)
        
        (0..<Int(count)).forEach {
            guard let info = tracksInfo?[$0] else {
                return
            }
            let i = info.pointee
            
            var type: TrackType = .unknown
            var values = [(key: TrackInfoKey, value: String)]()
            switch i.i_type {
            case libvlc_track_video:
                type = .video
                if let codec = libvlc_media_get_codec_description(i.i_type, i.i_codec) {
                    values.append((key: .codec, value: String(cString: codec)))
                }
                
                if let language = i.psz_language {
                    values.append((key: .language, value: String(cString: language)))
                }
                
                if let video = i.video {
                    let v = video.pointee
                    let w = v.i_width
                    let h = v.i_height
                    values.append((key: .size, value: "\(w)x\(h)"))
                    
                    values.append((key: .fps, value: "\(Float(v.i_frame_rate_num) / Float(v.i_frame_rate_den))"))
                    
                    let sampleAspectRatio = "\(v.i_sar_num):\(v.i_sar_den)"
                    values.append((key: .sampleAspectRatio, value: sampleAspectRatio))
                    
                    //            v.pose.f_field_of_view
                    //            v.pose.f_pitch
                    //            v.pose.f_roll
                    //            v.pose.f_yaw
                }
                
            case libvlc_track_audio:
                type = .audio
                if let codec = libvlc_media_get_codec_description(i.i_type, i.i_codec) {
                    values.append((key: .codec, value: String(cString: codec)))
                }
                
                if let language = i.psz_language {
                    values.append((key: .language, value: String(cString: language)))
                }
                
                if let audio = i.audio {
                    let a = audio.pointee
                    let sampleRate = a.i_rate
                    let channels = a.i_channels
                    
                    values.append((key: .sampleRate, value: "\(sampleRate) Hz"))
                    values.append((key: .channels, value: "\(channels)"))
                }
                
            case libvlc_track_text:
                type = .text
                if let codec = libvlc_media_get_codec_description(i.i_type, i.i_codec) {
                    values.append((key: .codec, value: String(cString: codec)))
                }
                
                if let language = i.psz_language {
                    values.append((key: .language, value: String(cString: language)))
                }
                
                if let subtitle = i.subtitle,
                    let encoding = subtitle.pointee.psz_encoding {
                    values.append((key: .encoding, value: String(cString: encoding)))
                }
                
            case libvlc_track_unknown:
                break
            default:
                break
            }
            if type != .unknown {
                let c = values.map({($0.key.rawValue, $0.value)})
                re.append(.init(type.rawValue, c))
            }
        }
        
        var stats = libvlc_media_stats_t()
        
        libvlc_media_get_stats(m, &stats)

//        stats.i_read_bytes
//        stats.f_input_bitrate
//        stats.i_demux_read_bytes
//        stats.f_demux_bitrate
//        stats.i_demux_corrupted
//        stats.i_demux_discontinuity
//        stats.i_decoded_video
//        stats.i_decoded_audio
//        stats.i_displayed_pictures
//        stats.i_lost_pictures
//        stats.i_played_abuffers
//        stats.i_lost_abuffers
//        stats.i_sent_packets
//        stats.i_sent_bytes
//        stats.f_send_bitrate
        
        let type = libvlc_media_get_type(m)
//        libvlc_media_type_unknown
//        libvlc_media_type_file
//        libvlc_media_type_directory
//        libvlc_media_type_disc
//        libvlc_media_type_stream
//        libvlc_media_type_playlist

        return re
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
    
// MARK: - Observer
    
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

