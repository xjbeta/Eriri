//
//  VLCMediaPlayerExtension.swift
//  Eriri
//
//  Created by xjbeta on 2020/2/13.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa

extension VLCMediaPlayer {
    
// MARK: - Infomations

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
                    values.append((key: .codec, value: codec.toString()))
                }
                
                if let language = i.psz_language {
                    values.append((key: .language, value: language.toString()))
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
                    values.append((key: .codec, value: codec.toString()))
                }
                
                if let language = i.psz_language {
                    values.append((key: .language, value: language.toString()))
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
                    values.append((key: .codec, value: codec.toString()))
                }
                
                if let language = i.psz_language {
                    values.append((key: .language, value: language.toString()))
                }
                
                if let subtitle = i.subtitle,
                    let encoding = subtitle.pointee.psz_encoding {
                    values.append((key: .encoding, value: encoding.toString()))
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
    
// MARK: - Observer
    
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
//                print("Event Attach: \(name.toString())")
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
