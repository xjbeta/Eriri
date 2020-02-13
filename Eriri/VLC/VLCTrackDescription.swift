//
//  VLCTrackDescription.swift
//  Eriri
//
//  Created by xjbeta on 2020/2/12.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa

class VLCTrackDescription: NSObject {
    struct Description {
        let index: Int
        let name: String
    }
    
    let currentIndex: Int
    var descriptions = [Description]()
    
    override init() {
        self.currentIndex = -1
    }
    
    required init(description: libvlc_track_description_t?,
                  count: Int32,
                  currentIndex: Int32) {
        self.currentIndex = Int(currentIndex)
        var des = description
        while des != nil {
            if let cStr = des?.psz_name,
                let id = des?.i_id {
                descriptions.append(
                    .init(index: Int(id),
                          name: cStr.toString()))
            } else {
                descriptions.append(
                    .init(index: -1,
                          name: ""))
            }
            if let next = des?.p_next {
                des = next.pointee
            } else {
                des = nil
            }
            if descriptions.count == count {
                des = nil
            }
        }
    }
}
