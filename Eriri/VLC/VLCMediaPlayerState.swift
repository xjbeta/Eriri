//
//  VLCMediaPlayerState.swift
//  Eriri
//
//  Created by xjbeta on 2020/11/1.
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
    case nothingSpecial
    case buffering
    
    init(state: libvlc_state_t) {
        switch state {
        case libvlc_NothingSpecial:
            self = .nothingSpecial
        case libvlc_Opening:
            self = .opening
        case libvlc_Buffering:
            self = .buffering
        case libvlc_Playing:
            self = .playing
        case libvlc_Paused:
            self = .paused
        case libvlc_Stopped:
            self = .stopped
        case libvlc_Ended:
            self = .ended
        case libvlc_Error:
            self = .error
        default:
            self = .error
        }
    }
}
