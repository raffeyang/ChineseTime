//
//  Welcome.swift
//  Chinese Time mac
//
//  Created by Leo Liu on 8/4/23.
//

import SwiftUI

struct Welcome: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(.image)
                .resizable()
                .frame(width: 120, height: 120)
            Text("華曆", comment: "Chinese Time")
                .font(.largeTitle.bold())
            HStack {
                Image(systemName: "menubar.rectangle")
                    .font(.largeTitle)
                    .frame(width: 70, height: 70)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading) {
                    Text("常駐狀態欄", comment: "Welcome, ring design - title")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.headline)
                        .padding(.vertical, 5)
                        .padding(.trailing, 5)
                    Text("華曆顯示於右上角狀態欄，點它展開", comment: "Welcome, display at status bar")
                }
            }
            .padding(.top, 5)
            HStack {
                Image(systemName: "pencil.and.outline")
                    .font(.largeTitle)
                    .frame(width: 70, height: 70)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading) {
                    Text("設置與詳述", comment: "Welcome, long press - title")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.headline)
                        .padding(.vertical, 5)
                        .padding(.trailing, 5)
                    Text("展開後點齒輪進設置，按你心意裝點最美華曆，其內亦有華曆詳述", comment: "Welcome, setting and documentation")
                }
            }
        }
        .padding(20)
    }
}


#Preview("Welcome") {
    Welcome()
        .frame(minWidth: 300, idealWidth: 350, maxWidth: 400, minHeight: 400, idealHeight: 600, maxHeight: 700, alignment: .center)
}
