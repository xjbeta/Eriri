//
//  VLCMediaType.swift
//  Eriri
//
//  Created by xjbeta on 2020/11/2.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa

enum VLCMediaType: Int {
    case unknown
    case file
    case directory
    case disc
    case stream
    case playlist
    
    init(type: libvlc_media_type_t) {
        switch type {
        case libvlc_media_type_file:
            self = .file
        case libvlc_media_type_directory:
            self = .directory
        case libvlc_media_type_disc:
            self = .disc
        case libvlc_media_type_stream:
            self = .stream
        case libvlc_media_type_playlist:
            self = .playlist
        default:
            self = .unknown
        }
    }
}
