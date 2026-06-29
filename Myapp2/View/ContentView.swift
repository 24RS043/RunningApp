import SwiftUI
import SwiftData

struct ContentView: View {
    @ObservedObject var authManager: AuthManager
    @StateObject var locationManager = LocationManager()
    
    // Firestore担当（履歴データを持つ係）を1つ作る
    @StateObject var store = RunRecordStore()
    @StateObject var profileStore = UserProfileStore()
    
    var body: some View {
        TabView {
            HomeView(store: store, profileStore: profileStore)        
                .tabItem { Label("ホーム", systemImage: "house.fill") }
            // 計測タブ
            RunView(locationManager: locationManager)
                .tabItem {
                    Label("計測", systemImage: "figure.run")
                }
            
            // 履歴タブ（store を渡す）
            HistoryView(store: store)
                .tabItem {
                    Label("履歴", systemImage: "list.bullet")
                }
            
            GameView(store: store, profileStore: profileStore)
                .tabItem {
                    Label("冒険", systemImage: "shield.fill")
                }
            
            ProfileView(profileStore: profileStore, authManager: authManager)
                .tabItem {
                    Label("設定", systemImage: "person.circle")
                }
        }
        .onAppear {
            // ログイン中のユーザーIDを store に伝える
            store.currentUserId = authManager.userId
            // LocationManager にも store を渡して、保存をお願いできるようにする
            locationManager.store = store
            locationManager.profileStore = profileStore
            // 履歴を読み込む
            store.load()
            
            profileStore.currentUserId = authManager.userId
            profileStore.load()
        }
    }
}
