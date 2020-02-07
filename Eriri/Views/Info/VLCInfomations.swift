//
//  VLCInfomations.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/29.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import SwiftUI
import VLCKit

class VLCInfomation: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    @Published var contents: [(String, String)]
    
    init(_ name: String, _ contents: [(String, String)]) {
        self.name = name
        self.contents = contents
    }
}

class VLCInfomations: ObservableObject {
    @Published var infos: [VLCInfomation] = [] {
        didSet {
            isEmpty = infos.count == 0
        }
    }
    @Published var isEmpty: Bool = true
    
    
    private var timer: DispatchSourceTimer?
    private var timerSuspend = true
    func start() {
        if let timer = timer {
            if timerSuspend {
                timer.resume()
                timerSuspend = false
            }
        } else {
            timer = DispatchSource.makeTimerSource(flags: [], queue: .main)
            guard let timer = timer else { return }
            timer.schedule(deadline: .now(), repeating: .seconds(1))
            timer.setEventHandler {
                self.updateInfos()
            }
            timer.resume()
            timerSuspend = false
        }
    }
    
    func stop() {
        timer?.suspend()
        timerSuspend = true
    }
    
    func frontmostPlayer() -> EririPlayer? {
        let utils = Utils.shared
        let p = utils.players.min { p1, p2 in
            p1.window.orderedIndex < p2.window.orderedIndex
        }
        return p
    }
    
    func updateInfos() {
        guard let player = frontmostPlayer() else {
            infos = []
            return
        }
        
//            VLCMediaTypeUnknown,
//            VLCMediaTypeFile,
//            VLCMediaTypeDirectory,
//            VLCMediaTypeDisc,
//            VLCMediaTypeStream,
//            VLCMediaTypePlaylist,

//            player.media.mediaType


//            VLCMediaParsedStatusInit = 0,
//            VLCMediaParsedStatusSkipped,
//            VLCMediaParsedStatusFailed,
//            VLCMediaParsedStatusTimeout,
//            VLCMediaParsedStatusDone

//            player.media.parsedStatus
        
        
//        print("metaDictionary", player.player.media.metaDictionary)
        
        //            player.media.numberOfSentBytes
        
        //            player.titleDescriptions
        //            player.audio.info
        
        //            VLCStreamOutput()
        
        infos = player.player.media.tracksInformation.compactMap { i -> VLCInfomation? in
            guard let d = i as? [String: Any],
                let type = d[VLCMediaTracksInformationType] as? String else {
                    return nil
            }
            
            let info = self.infoFormatter(type, d)
            return VLCInfomation(type.uppercased(), info)
        }
    }
    
    func infoFormatter(_ type: String?, _ d: [String: Any]) -> [(String, String)] {
        var info = [(String, String)]()
        
        
        
        ////                    infoLine("Format:")
        //                    infoLine("Type:")
        //                    infoLine("Video Resolution:")
        //                    infoLine("Frame Rate:")
        //                    infoLine("Decoded Format:")
        //                    infoLine("Color Space:")
        //                }
        //                Divider().frame(height: 20)
        //                Section(header: Text("Audio")) {
        //                    Spacer().frame(height: 6)
        //                    infoLine("Codec:")
        ////                    infoLine("Format:")
        //                    infoLine("Type:")
        //                    infoLine("Channels:")
        //                    infoLine("Sample Rate:")
        //                    infoLine("Bit Rate:")
        //                }
        //            }
        
        
        
        switch type {
        case VLCMediaTracksInformationTypeVideo:
            if let codec = d[VLCMediaTracksInformationCodec] as? UInt32 {
                let name = VLCMedia.codecName(forFourCC: codec, trackType: VLCMediaTracksInformationTypeVideo)
                info.append(("Codec", name))
            }
            
            if let videoWidth = d[VLCMediaTracksInformationVideoWidth] as? Int,
                let videoHeight = d[VLCMediaTracksInformationVideoHeight] as? Int {
                info.append(("Video Resolution", "\(videoWidth)x\(videoHeight)"))
            }
            
            
            if let bitrate = d[VLCMediaTracksInformationBitrate] as? Int {
                info.append(("BitRate", "\(bitrate)"))
            }
            
            if let fps = d[VLCMediaTracksInformationFrameRate] as? Int {
                info.append(("FPS", "\(fps)"))
            }
            
            
        case VLCMediaTracksInformationTypeAudio:
            
            if let codec = d[VLCMediaTracksInformationCodec] as? UInt32 {
                let name = VLCMedia.codecName(forFourCC: codec, trackType: VLCMediaTracksInformationTypeAudio)
                info.append(("Codec", name))
            }
            if let sampleRate = d[VLCMediaTracksInformationAudioRate] as? Int {
                info.append(("Sample Rate", "\(sampleRate) hz"))
            }
            
            if let bitrate = d[VLCMediaTracksInformationBitrate] as? Int {
                info.append(("Bitrate", "\(bitrate)"))
            }
            
            
            
            //            if let channelsNumber = d[VLCMediaTracksInformationAudioChannelsNumber] as? Int {
            //                var v = "number: \(channelsNumber)"
            //
            //                switch channelsNumber {
            //                case 1:
            //                    v = "Mono"
            //                case 2:
            //                    v = "Stereo"
            //                default:
            //                    break
            //
            //                }
            //
            //
            //
            //            }
            //            VLCMediaTracksInformationCodecProfile
            //            VLCMediaTracksInformationCodecLevel
            
            
            
        case VLCMediaTracksInformationTypeText:
            if let codec = d[VLCMediaTracksInformationCodec] as? UInt32 {
                let name = VLCMedia.codecName(forFourCC: codec, trackType: VLCMediaTracksInformationTypeText)
                info.append(("Codec", name))
            }
            
            if let language = d[VLCMediaTracksInformationLanguage] as? String {
                info.append(("Language", language))
            }
            
            if let encoding = d[VLCMediaTracksInformationTextEncoding] as? String {
                info.append(("Encoding", encoding))
            }
            
        case VLCMediaTracksInformationTypeUnknown:
            break
        default:
            break
        }
        
        return info
    }
    

}

