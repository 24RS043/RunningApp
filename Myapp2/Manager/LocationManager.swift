//
//  LocationManager.swift
//  MyApp2
//
//  Created by KoudaTakuma on 2026/05/14.
//

import SwiftUI
import CoreLocation //GPSを使うための機能
import Combine //データの変化を画面に自動反映する仕組み
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    //NSObject→iosの基本クラス ObservableObject→画面とデータを連動させる CLLocationManagerDelegate→GPS更新を受け取る
    
    let manager = CLLocationManager() //iPhoneのGPS機能そのもの
    
    @Published var elapsedTime = 0 //経過時間
    @Published var distance: Double = 0.0
    @Published var calories: Double = 0.0
    var timer: Timer? //Timerを保存
    var previousLocation: CLLocation? //前回のGPS位置
    
    @Published var route: [CLLocationCoordinate2D] = []
    //値変更時に画面更新　CLLocationCoordinate2D　緯度経度
    
    // ラップ（1kmごとの区間タイム・秒）を貯める箱
    @Published var laps: [Int] = []
    // 次に記録すべき距離の区切り（最初は1000m）
    var nextLapDistance: Double = 1000
    // 前のラップを刻んだときの経過時間（区間タイムの計算に使う）
    var lastLapTime: Int = 0
    var profileStore: UserProfileStore?
    
    // Firestoreへの保存をお願いする係（ContentViewからセットされる）
    var store: RunRecordStore?
    
    @Published var isRunning = false
    @Published var lastRunQualified = false
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6812, longitude:139.7671),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    override init() { //クラスが作られたときに最初に動く関数
        super.init()  //親クラス(NSObject)の初期化
        
        manager.delegate = self //GPS更新があったらこのクラスに知らせる
        manager.requestWhenInUseAuthorization() //位置情報の許可をユーザーに聞く
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
        
        // ラップ関連もリセット
        laps.removeAll()
        nextLapDistance = 1000
        lastLapTime = 0
    }
    
    func stopRunning() { //ランニング終了
        isRunning = false //走っていない状態
        
        manager.stopUpdatingLocation()//GPS更新を停止
        
        timer?.invalidate() //タイマー停止
        let weight = profileStore?.weight ?? 0
        calories = weight * (distance / 1000) * 1.05
        
        let newRecord = RunRecord( //RunRecord型の新しいランニング記録を作成
            id: UUID().uuidString,
            date: Date(),//現在日時を保存
            distance: distance, //現在の走行距離
            time: elapsedTime,//経過時間
            calories: calories,
            route: route.map{RoutePoint(latitude: $0.latitude, longitude: $0.longitude)},
            laps: laps //記録したラップを入れる
        )
        
        // 保存と履歴管理はFirestore担当(store)にお願いする
        store?.add(newRecord)
        // 1km以上走っていたらミッション対象としてフラグを立てる
        if distance >= 1000 {
            lastRunQualified = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //位置が変わるたびに呼ばれる関数
        guard let location = locations.last else { return }
        //最新の位置だけ取り出す
        
        // 精度が悪い点・古い点は捨てる（GPSのブレ対策）
        guard location.horizontalAccuracy >= 0,        // マイナスは無効な点
              location.horizontalAccuracy <= 20 else { // 誤差20mより大きい点は使わない
            return
        }
        
        route.append(location.coordinate)
        //現在地をroute配列に追加
        
        if let previous = previousLocation { //前回の位置があるなら
            let newDistance = location.distance(from: previous)
            //前回地点から現在地点までの距離を計算
            distance += newDistance
        }
        
        // 距離が次の区切り（1km, 2km, …）を超えたらラップを記録する
        while distance >= nextLapDistance {
            let lapTime = elapsedTime - lastLapTime   // この1kmにかかった秒数
            laps.append(lapTime)
            lastLapTime = elapsedTime
            nextLapDistance += 1000                   // 次の区切りへ
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
    }
}
