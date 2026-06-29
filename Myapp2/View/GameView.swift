//
//  GameView.swift
//  Myapp2
//
//  Created by  KoudaTakuma       on 2026/06/26.
//
import SwiftUI

struct GameView: View {
    @ObservedObject var store: RunRecordStore
    @ObservedObject var profileStore: UserProfileStore
    // 表示中のページ（キャラ or マップ）
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 上部の切り替えセグメント
                Picker("", selection: $selectedTab) {
                    Text("キャラ").tag(0)
                    Text("マップ").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // 選択に応じて中身を切り替える
                if selectedTab == 0 {
                    CharacterContent(profileStore: profileStore)
                } else {
                    WorldMapContent(store: store, profileStore: profileStore)
                }
            }
            .navigationTitle("冒険")
        }
    }
}
