//
//  MyApp2App.swift
//  MyApp2
//
//  Created by  KoudaTakuma       on 2026/05/14.
//

import SwiftUI
import FirebaseCore

// Firebaseを初期化するためのクラス
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure() // Firebaseを起動
        return true
    }
}

@main
struct MyApp2App: App {
    // 上で作ったAppDelegateをアプリに登録
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // ログインの係をアプリ全体で1つ持つ
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            // ログイン状態によって表示する画面を切り替える
            if authManager.isLoggedIn {
                ContentView(authManager: authManager)   // ログイン済み → アプリ本体
            } else {
                LoginView(authManager: authManager)   // 未ログイン → ログイン画面
            }
        }
    }
}
