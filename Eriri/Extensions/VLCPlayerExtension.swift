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
}
