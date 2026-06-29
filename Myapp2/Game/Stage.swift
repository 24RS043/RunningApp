//
//  Stage.swift
//  Myapp2
//
//  Created by  KoudaTakuma       on 2026/06/25.
//

import Foundation

// ステージの種類
enum StageType: Hashable {
    case battle   // 戦闘（雑魚敵）
    case shop     // ショップ
    case boss     // ボス

    var iconName: String {
        switch self {
        case .battle: return "figure.fencing"
        case .shop:   return "cart.fill"
        case .boss:   return "crown.fill"
        }
    }

    var label: String {
        switch self {
        case .battle: return "戦闘"
        case .shop:   return "ショップ"
        case .boss:   return "ボス"
        }
    }
    
    // 挑戦に必要なポイント
    var requiredPoints: Int {
        switch self {
        case .battle: return 1
        case .boss:   return 2
        case .shop:   return 0   // ショップは消費なし
        }
    }
}

// 1つのステージ
struct Stage: Identifiable, Hashable {
    let id: Int                  // 何番目のステージか（0始まり）
    let type: StageType
    let requiredDistance: Double // このステージを解放するのに必要な累計距離(m)

    // 解放済みかどうかを判定（累計距離を渡す）
    func isUnlocked(totalDistance: Double) -> Bool {
        totalDistance >= requiredDistance
    }
}

// ステージ一覧（仮データ・あとで自由に増やせる）
enum StageData {
    // 1kmごとに1ステージ進む設定
    static let all: [Stage] = [
        Stage(id: 0, type: .battle, requiredDistance: 0),
        Stage(id: 1, type: .battle, requiredDistance: 1000),
        Stage(id: 2, type: .battle,   requiredDistance: 2000),
        Stage(id: 3, type: .battle, requiredDistance: 3000),
        Stage(id: 4, type: .battle,   requiredDistance: 4000),
        Stage(id: 5, type: .battle, requiredDistance: 5000),
        Stage(id: 6, type: .battle,   requiredDistance: 6000),
        Stage(id: 7, type: .boss,   requiredDistance: 7000)
    ]
}
