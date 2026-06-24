import SwiftUI

struct ContentView: View {
    @ObservedObject var authManager: AuthManager
    @StateObject var locationManager = LocationManager()

    // Firestore担当（履歴データを持つ係）を1つ作る
    @StateObject var store = RunRecordStore()

    var body: some View {
        TabView {
            // 計測タブ
            RunView(locationManager: locationManager)
                .tabItem {
                    Label("計測", systemImage: "figure.run")
                }

            // 履歴タブ（store を渡す）
            HistoryView(store: store, authManager: authManager)
                .tabItem {
                    Label("履歴", systemImage: "list.bullet")
                }
        }
        .onAppear {
            // ログイン中のユーザーIDを store に伝える
            store.currentUserId = authManager.userId
            // LocationManager にも store を渡して、保存をお願いできるようにする
            locationManager.store = store
            // 履歴を読み込む
            store.load()
        }
    }
}
