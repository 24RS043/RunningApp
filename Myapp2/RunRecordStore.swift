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
    
    // 今ログインしているユーザーのID（誰の記録かを区別するのに使う）
    var currentUserId: String?
    
    private let db = Firestore.firestore()
    
    // 1件の記録をFirestoreに保存する
    func add(_ record: RunRecord) {
        // route を文字列(JSON)に変換する
        var routeString = ""
        if let routeData = try? JSONEncoder().encode(record.route),
           let str = String(data: routeData, encoding: .utf8) {
            routeString = str
        }
        
        // lapsを文字列(JSON)に変換する
        var lapsString = ""
        if let lapsData = try? JSONEncoder().encode(record.laps),
           let str = String(data: lapsData, encoding: .utf8) {
            lapsString = str
        }
        
        let ref = db.collection("runRecords").addDocument(data: [
            "date": record.date,
            "distance": record.distance,
            "time": record.time,
            "calories": record.calories,
            "userId": currentUserId ?? "",
            "route": routeString,
            "laps": lapsString
        ]) { error in
            if let error = error {
                print("Firestore保存エラー: \(error.localizedDescription)")
            } else {
                print("Firestoreに保存成功！")
            }
        }
        
        // 画面の一覧にもすぐ反映し、FirestoreのIDを覚えさせる
        var saved = record
        saved.firestoreId = ref.documentID
        DispatchQueue.main.async {
            self.records.insert(saved, at: 0)   // 新しい記録を先頭に追加
        }
    }
    
    // 自分の記録をFirestoreから読み込む
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
                    var route: [RoutePoint] = []
                    if let routeString = data["route"] as? String,
                       let routeData = routeString.data(using: .utf8),
                       let decoded = try? JSONDecoder().decode([RoutePoint].self, from: routeData) {
                        route = decoded
                    }
                    
                    // 保存しておいた文字列を laps に戻す
                    var laps: [Int] = []
                    if let lapsString = data["laps"] as? String,
                       let lapsData = lapsString.data(using: .utf8),
                       let decoded = try? JSONDecoder().decode([Int].self, from: lapsData) {
                        laps = decoded
                    }
                    
                    return RunRecord(
                        date: timestamp.dateValue(),
                        distance: distance,
                        time: time,
                        calories: calories,
                        route: route,
                        firestoreId: doc.documentID,
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
            if let docId = record.firestoreId {
                db.collection("runRecords").document(docId).delete { error in
                    if let error = error {
                        print("Firestore削除エラー: \(error.localizedDescription)")
                    } else {
                        print("Firestoreから削除成功")
                    }
                }
            }
        }
        records.remove(atOffsets: offsets)
    }
}
