//
//  OpenURLView.swift
//  Eriri
//
//  Created by xjbeta on 2020/2/2.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import SwiftUI

struct OpenURLView: View {
    @State var urlValue: String = ""
    
    let window: NSWindow
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
            
            VStack(alignment: .trailing) {
                VStack(alignment: .leading) {
                    Text("URL:")
                        .font(.callout)
                        .bold()
                    URLTextField(window: window, stringValue: $urlValue)
                }
                Spacer(minLength: 30)
                WindowButtons(window: window, title: "Open") {
                    self.openURL()
                }
            }.frame(width: 400)
            .padding()
        }
        .padding(.top, -22)
    }
    
    func openURL() {
        print(#function, "\(self.urlValue)")
        guard let u = URL(string: urlValue) else { return }
        Utils.shared.newPlayerWindow(u)
        self.urlValue = ""
        self.window.close()
    }
}

struct OpenURLView_Previews: PreviewProvider {
    static var previews: some View {
        OpenURLView(urlValue: "url", window: NSWindow())
    }
}
