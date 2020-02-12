//
//  InfoContentView.swift
//  Eriri
//
//  Created by xjbeta on 2020/1/28.
//  Copyright © 2020 xjbeta. All rights reserved.
//

import SwiftUI

struct InfoContentView: View {
    @ObservedObject var infos: VLCInfomations
    
    var infoForm: some View {
        Form {
            ForEach(infos.infos, id: \.id) { info in
                Section(header: Text(info.name)) {
                    Spacer().frame(height: 6)
                    ForEach(info.contents, id: \.0) { kv in
                        self.infoLine(kv.0, kv.1)
                    }
                    if self.infos.infos.last?.id != info.id {
                        Divider().frame(height: 20)
                    }
                }
            }
        }
    }
    
    var body: some View {
        if !infos.isEmpty {
            return AnyView(infoForm
                .frame(width: 350)
                .padding())
        } else {
            return AnyView(Text("None")
                .font(.title)
                .padding(.all, 40))
        }
    }
    
    func infoLine(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
                .frame(width: 120, alignment: .leading)
                .padding(.leading)
                .font(Font.caption.bold())
            Text(value)
                .frame(alignment: .leading)
                .font(.caption)
        }.padding(.all, 4)
    }
    
}
