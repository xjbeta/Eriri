//
//  VLCPlayerExtension.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/28.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import VLCKit

extension VLCMediaPlayer {
    func togglePlay() {
        if isPlaying, canPause {
            pause()
        } else if shouldReplay() {
            position = 0
            play()
        } else {
            play()
        }
    }
    
    private func shouldReplay() -> Bool {
        guard let timeStr = remainingTime.stringValue,
            timeStr.count >= 2 else {
            return false
        }
        
        if timeStr.dropFirst(timeStr.count - 2) == "00",
            state == .paused,
            position > 0.99 {
            return true
        }
        return false
    }
    
    func metaData() -> [(String, String)] {
        guard let media = media else { return [] }
        let metaDictionaryKeys =
//            [VLCMetaInformationTitle,
//             VLCMetaInformationArtist,
//             VLCMetaInformationGenre,
//             VLCMetaInformationCopyright,
//             VLCMetaInformationAlbum,
//             VLCMetaInformationTrackNumber,
//             VLCMetaInformationDescription,
//             VLCMetaInformationRating,
//             VLCMetaInformationDate,
//             VLCMetaInformationSetting,
//             VLCMetaInformationURL,
//             VLCMetaInformationLanguage,
//             VLCMetaInformationNowPlaying,
//             VLCMetaInformationPublisher,
//             VLCMetaInformationEncodedBy,
//             VLCMetaInformationArtworkURL,
//             VLCMetaInformationArtwork,
//             VLCMetaInformationTrackID,
//             VLCMetaInformationTrackTotal,
//             VLCMetaInformationDirector,
//             VLCMetaInformationSeason,
//             VLCMetaInformationEpisode,
//             VLCMetaInformationShowName,
//             VLCMetaInformationActors,
//             VLCMetaInformationAlbumArtist,
//             VLCMetaInformationDiscNumber]
        
        [VLCMetaInformationTitle,
        VLCMetaInformationArtist,
        VLCMetaInformationAlbum,
        VLCMetaInformationDate,
        VLCMetaInformationGenre,
        VLCMetaInformationTrackNumber,
        VLCMetaInformationDiscNumber,
        VLCMetaInformationNowPlaying,
        VLCMetaInformationLanguage]
        
        var re = [(String, String)]()
        metaDictionaryKeys.forEach {
            let data = media.metadata(forKey: $0)
            re.append(($0, data))
        }
        return re
    }
    
    func subtitles() -> [(index: Int, name: String)] {
        guard let indexs = videoSubTitlesIndexes as? [Int],
            let names = videoSubTitlesNames as? [String],
            indexs.count == names.count else {
            return []
        }
        var re = [(index: Int, name: String)]()
        indexs.enumerated().forEach {
            re.append(($0.element, names[$0.offset]))
        }
        
        return re
    }
    
    func audioTracks() -> [(index: Int, name: String)] {
        guard let indexs = audioTrackIndexes as? [Int],
            let names = audioTrackNames as? [String],
            indexs.count == names.count else {
            return []
        }
        var re = [(index: Int, name: String)]()
        indexs.enumerated().forEach {
            re.append(($0.element, names[$0.offset]))
        }
        
        return re
    }
}
