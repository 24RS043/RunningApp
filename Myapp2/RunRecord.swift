//
//  RunRecord.swift
//  MyApp2
//
//  Created by KoudaTakuma on 2026/05/20.
//

import Foundation

// ランニング履歴を保存するための構造体
struct RunRecord: Identifiable, Codable {

    // 各履歴を識別するための一意のID
    let id = UUID()

    // ランニングを終了した日時
    let date: Date

    // 走行距離（単位：m）
    let distance: Double

    // 走行時間（単位：秒）
    let time: Int
    
    //カロリー
    let calories: Double
    
    //走行ルート
    var route: [RoutePoint] = []
}

struct RoutePoint: Codable {
    let latitude: Double
    let longitude: Double
}
