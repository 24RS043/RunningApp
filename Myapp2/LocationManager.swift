//
//  File.swift
//  MyApp2
//
//  Created by  KoudaTakuma       on 2026/05/14.
//

import SwiftUI
import CoreLocation //GPSを使うための機能
import Combine //データの変化を画面に自動反映する仕組み
import MapKit
import FirebaseFirestore
import FirebaseAuth

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    //NSObject→iosの基本クラス ObservableObject→画面とデータを連動させる CLLocationManagerDelegate→GPS更新を受け取る
    
    let manager = CLLocationManager() //iPhoneのGPS機能そのもの
    
    //    @Published var latitude: Double = 0.0  //緯度を保存する変数
    //    @Published var longitude: Double = 0.0 //経度を保存する仕組み
    @Published var elapsedTime = 0 //経過時間
    @Published var distance: Double = 0.0
    @Published var calories: Double = 0.0
    var timer: Timer? //Timerを保存
    var previousLocation: CLLocation? //前回のGPS位置
    
    
    @Published var route: [CLLocationCoordinate2D] = []
    //値変更時に画面更新　CLLocationCoordinate2D　緯度経度
    @Published var records: [RunRecord] = []
    var currentUserId: String?   // 今ログインしているユーザーのID
    
    
    @Published var isRunning = false
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude:139.7671),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    override init() { //クラスが作られたときに最初に動く関数
        super.init()  //親クラス(NSObject)の初期化
        
        manager.delegate = self //GPS更新があったらこのクラスに知らせる
        manager.requestWhenInUseAuthorization() //位置情報の許可をユーザーに聞く
        
        loadRecords() //保存していた履歴を読み込む
        loadRecordsFromFirestore()
    }
    
    func startRunning() { //ランニング開始
        
        print("Start")
        
        manager.startUpdatingLocation() // 継続取得
        
        
        isRunning = true //走行中
        
        distance = 0
        elapsedTime = 0
        previousLocation = nil //前回のGPS位置
        
        
        timer = Timer.scheduledTimer(withTimeInterval:1, repeats: true)
        {_ in self.elapsedTime += 1
        }
        
        route.removeAll() //前回のランニングの線を削除
    }
    
    func stopRunning() { //ランニング終了
        
        isRunning = false //走っていない状態
        
        manager.stopUpdatingLocation()//GPS更新を停止
        
        timer?.invalidate() //タイマー停止
        let weight = Double(
            UserDefaults.standard.string(forKey: "weight") ?? "0"
        ) ?? 0
        calories = weight * (distance / 1000) * 1.05//カロリー計算
        print(records)
        
        let newRecord = RunRecord( //RunRecord型の新しいランニング記録を作成開始
            date: Date(),//現在日時を保存
            distance: distance, //現在の走行距離
            time: elapsedTime,//経過時間
            calories: calories,
            route: route.map{RoutePoint(latitude: $0.latitude, longitude: $0.longitude)}
        )
        
        records.append(newRecord) //作った記録を履歴配列に追加
        
        saveRecords() //アプリを閉じても履歴が消えないようにする
        
        // Firestore（クラウド）にも保存する
        let db = Firestore.firestore()
        
        // routeを文字列(JSON)に変換する
        var routeString = ""
        if let routeData = try? JSONEncoder().encode(newRecord.route),
           let str = String(data: routeData, encoding: .utf8) {
            routeString = str
        }
        
        db.collection("runRecords").addDocument(data: [
            "date": newRecord.date,
            "distance": newRecord.distance,
            "time": newRecord.time,
            "calories": newRecord.calories,
            "userId": currentUserId ?? "" ,  // 誰の記録かを記録する
            "route": routeString
        ]) { error in
            if let error = error {
                print("Firestore保存エラー: \(error.localizedDescription)")
            } else {
                print("Firestoreに保存成功！")
            }
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //位置が変わるたびに呼ばれる関数
        guard let location = locations.last else { return }
        //最新の位置だけ取り出す
        
        route.append(location.coordinate)
        //現在地をroute配列に追加
        
        if let previous = previousLocation { //前回の位置を追加するなら
            
            let newDistance = location.distance(from: previous)
            //前回地点から現在地点までの距離を計算
            
            distance += newDistance
        }
        
        previousLocation = location
        
        DispatchQueue.main.async {
            self.region = MKCoordinateRegion(
                center:location.coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.01,
                    longitudeDelta: 0.01
                )
            )
        }
        //        latitude = location.coordinate.latitude  //緯度を更新
        //        longitude = location.coordinate.longitude//経度を更新
    }
    
    func saveRecords() { //ランニング履歴を保存するための関数
        
        if let encoded = try? JSONEncoder().encode(records) {
            
            UserDefaults.standard.set(
                encoded,
                forKey: "records"
            )
        }
    }
    
    func loadRecords() { //iPhoneの保存領域へデータ保存
        
        if let data = UserDefaults.standard.data(
            forKey: "records"
        ),
           
            let decoded = try? JSONDecoder().decode(
                [RunRecord].self,
                from: data
            ) {
            
            records = decoded
        }
    }
    
    func deleteRecords(at offsets: IndexSet) { //履歴を削除
        records.remove(atOffsets: offsets)
        saveRecords() //削除後に保存
    }
    
    func loadRecordsFromFirestore() {
        let db = Firestore.firestore()
        
        guard let uid = currentUserId else {
            // ログインしていなければ何も表示しない
            DispatchQueue.main.async { self.records = [] }
            return
        }
        
        
        db.collection("runRecords")
            .whereField("userId", isEqualTo: uid)   // 自分の記録だけ
            .order(by: "date", descending: true)  // 新しい順に並べる
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Firestore読み込みエラー: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                
                let loaded = documents.compactMap { doc -> RunRecord? in
                    let data = doc.data()
                    
                    guard let timestamp = data["date"] as? Timestamp,
                          let distance = data["distance"] as? Double,
                          let calories = data["calories"] as? Double else {
                        return nil
                    }
                    
                    // time は Int / Int64 どちらで返っても拾えるようにする
                    let time = (data["time"] as? Int) ?? Int(data["time"] as? Int64 ?? 0)
                    
                    // 保存しておいた文字列を route に戻す
                    var route: [RoutePoint] = []
                    if let routeString = data["route"] as? String,
                       let routeData = routeString.data(using: .utf8),
                       let decoded = try? JSONDecoder().decode([RoutePoint].self, from: routeData) {
                        route = decoded
                    }
                    
                    return RunRecord(
                        date: timestamp.dateValue(),
                        distance: distance,
                        time: time,
                        calories: calories,
                        route: route  // 復元したルートを入れる
                    )
                }
                
                DispatchQueue.main.async {
                    self.records = loaded
                }
            }
    }
    
}
