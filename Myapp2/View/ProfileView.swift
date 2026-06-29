//
//  ProfileView.swift
//  Myapp2
//
//  Created by  KoudaTakuma       on 2026/06/24.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var profileStore: UserProfileStore
    @ObservedObject var authManager: AuthManager
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section("プロフィール") {
                    TextField("表示名（ニックネーム）", text: $profileStore.displayName)
                    
                    TextField("体重(kg)", value: $profileStore.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                }
                Section {
                    Button("保存") {
                        profileStore.save()
                    }
                }
                
                Section {
                    Button("ログアウト", role: .destructive) {
                        authManager.logout()
                    }
                }
            }
            .navigationTitle("設定")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") {
                        isFocused = false// キーボードを閉じる
                    }
                }
            }
        }
    }
}
