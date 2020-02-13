//
//  LoginViewInfo.swift
//  Eriri
//
//  Created by xjbeta on 2020/2/4.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import Cocoa
import SwiftUI

class LoginViewInfo: ObservableObject {
    @Published var title = ""
    @Published var message = ""
    @Published var username = ""
    @Published var password = ""
    @Published var askingForStorage = false
    @Published var storePassword = false
}
