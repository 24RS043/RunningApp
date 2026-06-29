//
//  RunRecordStore.swift
//  Myapp2
//
//  Created by  KoudaTakuma       on 2026/06/23.
//

//  履歴データ（records）をFirestoreで管理する係
//

import SwiftUI
import FirebaseFirestore
import Combine

class RunRecordStore: ObservableObject {
    
    // 履歴一覧。これまで LocationManager が持っていたものをこちらに移した。
    @Published var records: [RunRecord] = []
    @Published var errorMessage: String? = nil
    
    // 今ログインしているユーザーのID（誰の記録かを区別するのに使う）
    var currentUserId: String?
    
    private let db = Firestore.firestore()
    
    // 全記録の合計距離(m)
    var totalDistance: Double {
        records.reduce(0) { $0 + $1.distance }
    }
    
    // ラン回数
    var runCount: Int {
        records.count
    }
    
    // 累計時間(秒)
    var totalTime: Int {
        records.reduce(0) { $0 + $1.time }
    }
    
    // 累計カロリー
    var totalCalories: Double {
        records.reduce(0) { $0 + $1.calories }
    }
    
    // 最長距離(m)
    var longestDistance: Double {
        records.map { $0.distance }.max() ?? 0
    }
    
    // 平均ペース(秒/km)。距離0なら0
    var averagePace: Double {
        let totalKm = totalDistance / 1000
        guard totalKm > 0 else { return 0 }
        return Double(totalTime) / totalKm
    }
    
    // 1件の記録をFirestoreに保存する
    func add(_ record: RunRecord) {
        
        let ref = db.collection("runRecords").addDocument(data: [
            "date": record.date,
            "distance": record.distance,
            "time": record.time,
            "calories": record.calories,
            "userId": currentUserId ?? "",
            // ネイティブ配列・マップでそのまま保存
            "route": record.route.map { ["latitude": $0.latitude, "longitude": $0.longitude] },
            "laps": record.laps
        ]) { error in
            if let error = error {
                print("Firestore保存エラー: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "記録の保存に失敗しました"
                }
            } else {
                print("Firestoreに保存成功！")
            }
        }
        
        var saved = record
        saved.id = ref.documentID
        self.records.insert(saved, at: 0)
    }    // 自分の記録をFirestoreから読み込む
    func load() {
        guard let uid = currentUserId else {
            // ログインしていなければ何も表示しない
            DispatchQueue.main.async { self.records = [] }
            return
        }
        
        db.collection("runRecords")
            .whereField("userId", isEqualTo: uid)   // 自分の記録だけ
            .order(by: "date", descending: true)    // 新しい順に並べる
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
                    // route を戻す
                    var route: [RoutePoint] = []
                    if let routeArray = data["route"] as? [[String: Double]] {
                        route = routeArray.compactMap { dict in
                            guard let lat = dict["latitude"], let lon = dict["longitude"] else { return nil }
                            return RoutePoint(latitude: lat, longitude: lon)
                        }
                    }
                    
                    // laps を戻す
                    let laps = (data["laps"] as? [Int]) ?? []
                    
                    return RunRecord(
                        id: doc.documentID,
                        date: timestamp.dateValue(),
                        distance: distance,
                        time: time,
                        calories: calories,
                        route: route,
                        laps: laps
                    )
                }
                
                DispatchQueue.main.async {
                    self.records = loaded
                }
            }
    }
    
    // スワイプ削除：Firestoreと画面の両方から消す
    func delete(at offsets: IndexSet) {
        for index in offsets {
            let record = records[index]
            db.collection("runRecords").document(record.id).delete { error in
                if let error = error {
                    print("Firestore削除エラー: \(error.localizedDescription)")
                    // 削除失敗したら画面に戻す
                    DispatchQueue.main.async {
                        self.errorMessage = "削除に失敗しました"
                        self.load()
                    }
                } else {
                    print("Firestoreから削除成功")
                }
            }
        }
        // Firestoreの完了を待たず画面からは先に消す（楽観的削除）
        records.remove(atOffsets: offsets)
    }
}
