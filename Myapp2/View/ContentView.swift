import SwiftUI

struct ContentView: View {
    // 位置情報・記録を管理するクラスを1つだけ作る
    // ここで作った1つを両方のタブで共有する（@StateObjectは画面の持ち主が使う）
    @ObservedObject var authManager: AuthManager
    @StateObject var locationManager = LocationManager()
    
    var body: some View {
        // TabView：画面下のタブで「計測」と「履歴」を切り替える
        TabView {
            // 計測タブ：地図・距離・時間・Start/Stop
            RunView(locationManager: locationManager)
                .tabItem {
                    // tabItem：タブの見た目（文字＋アイコン）
                    Label("計測", systemImage: "figure.run")
                }
            
            // 履歴タブ：過去の記録一覧
            HistoryView(locationManager: locationManager)
                .tabItem {
                    Label("履歴", systemImage: "list.bullet")
                }
        }
        // 画面が出たとき、ログイン中のユーザーIDを LocationManager に渡す
        .onAppear {
            locationManager.currentUserId = authManager.userId
            locationManager.loadRecordsFromFirestore()
        }
    }
}
