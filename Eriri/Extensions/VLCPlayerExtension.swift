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
        } else {
            play()
        }
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
}
