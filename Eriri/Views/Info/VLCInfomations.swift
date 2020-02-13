//
//  VLCInfomations.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/29.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import SwiftUI

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
        infos = player.player.tracksInformation()
    }
}

