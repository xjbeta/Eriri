//
//  LoginView.swift
//  Eriri
//
//  Created by xjbeta on 2020/2/4.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import SwiftUI

struct LoginView: View {
    let window: NSWindow
    @ObservedObject var info: LoginViewInfo
    let complete: (() -> Void)
    
    var rightView: some View {
        VStack(alignment: .leading) {
            Text(info.title)
                .bold()
            Text(info.message)
                .font(.system(size: 11))
            Spacer(minLength: 20)
            Text("Username")
                .font(.system(size: 11))
            TextField("", text: $info.username)
            Text("Password")
                .font(.system(size: 11))
            SecureField("", text: $info.password)
            Spacer(minLength: 20)
            HStack(alignment: .center) {
                Toggle("Remenber", isOn: $info.storePassword)
                    .opacity(info.askingForStorage ? 1 : 0)
                WindowButtons(window: window, title: "OK") {
                    self.complete()
                    self.window.close()
                }
            }
        }
        .frame(width: 350)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 70, height: 70)
            rightView
        }.padding(.all, 20)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var info: LoginViewInfo {
        let i = LoginViewInfo()
        i.title = "LoginView Title"
        i.message = "LoginView Message"
        i.askingForStorage = true
        return i
    }
    static var complete: (() -> Void) = {
        print("complete")
    }
    
    static var previews: some View {
        LoginView(window: NSWindow(), info: info, complete: complete)
    }
}
