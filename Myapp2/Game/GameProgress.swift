//
//  GameProgress.swift
//  Myapp2
//
//  Created by  KoudaTakuma       on 2026/06/26.
//

import Foundation
import SwiftData

@Model
class GameProgress {
    // これまで到達した累計距離の最大値(m)
    var maxReachedDistance: Double
    
    // 最後にログインボーナスを受け取った日
    var lastLoginBonusDate: Date?
    
    // 最後にランニング達成ボーナスを受け取った日
    var lastRunBonusDate: Date?
    
    // すでにポイントに換算した距離(m)。ここまでは3kmごとのptを配り済み。
    var rewardedDistance: Double
    
    init(
        maxReachedDistance: Double = 0,
        lastLoginBonusDate: Date? = nil,
        lastRunBonusDate: Date? = nil,
        rewardedDistance: Double = 0
    ) {
        self.maxReachedDistance = maxReachedDistance
        self.lastLoginBonusDate = lastLoginBonusDate
        self.lastRunBonusDate = lastRunBonusDate
        self.rewardedDistance = rewardedDistance
    }
}
