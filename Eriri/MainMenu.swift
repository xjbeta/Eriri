//
//  MainMenu.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/27.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa

class MainMenu: NSObject, NSMenuItemValidation {
    var delegate: AppDelegate? {
        return NSApp.delegate as? AppDelegate
    }
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true
    }

// MARK: - File
    @IBAction func open(_ sender: NSMenuItem) {
        delegate?.showMediaOpenPanel()
    }
    
    
// MARK: - Video Items

    @IBAction func halfSize(_ sender: NSMenuItem) {
    }
    @IBAction func normalSize(_ sender: NSMenuItem) {
    }
    @IBAction func doubleSize(_ sender: NSMenuItem) {
    }
    @IBAction func fitToScreen(_ sender: NSMenuItem) {
    }
    
    
    

}
