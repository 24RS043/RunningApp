//
//  MissionManager.swift
//  Myapp2
//
//  Created by  KoudaTakuma       on 2026/06/26.
//

import Foundation
import SwiftData

// ミッションの判定とポイント付与をまとめる係
struct MissionManager {
    
    // 3つのミッションをまとめてチェックする
    // character: ポイントを足す相手 / progress: 受取記録 / totalDistance: 現在の累計距離(m)
    // 戻り値: 今回新しくもらえたポイントの合計（画面通知用）
    @discardableResult
    static func checkAll(
        character: GameCharacter,
        progress: GameProgress,
        totalDistance: Double
    ) -> Int {
        var earned = 0
        earned += checkLoginBonus(character: character, progress: progress)
        earned += checkRunBonus(character: character, progress: progress, totalDistance: totalDistance)
        earned += checkDistanceMilestone(character: character, progress: progress, totalDistance: totalDistance)
        return earned
    }
    
    // ① ログインボーナス（1日1回 +1pt）
    static func checkLoginBonus(character: GameCharacter, progress: GameProgress) -> Int {
        if isSameDay(progress.lastLoginBonusDate, Date()) {
            return 0   // 今日はもう受け取り済み
        }
        character.points += 1
        progress.lastLoginBonusDate = Date()
        return 1
    }
    
    // ② ランニング達成ボーナス（1日1回・1km以上で +2pt）
    static func checkRunBonus(character: GameCharacter, progress: GameProgress, totalDistance: Double) -> Int {
        // この呼び出しは「1km以上のランを終えた直後」だけ呼ぶ前提
        if isSameDay(progress.lastRunBonusDate, Date()) {
            return 0   // 今日はもう受け取り済み
        }
        character.points += 2
        progress.lastRunBonusDate = Date()
        return 2
    }
    
    // ③ 距離達成（累計3kmごとに +1pt）
    static func checkDistanceMilestone(character: GameCharacter, progress: GameProgress, totalDistance: Double) -> Int {
        let step: Double = 3000   // 3km
        var earned = 0
        
        // まだポイントを配っていない距離ぶんを3kmごとに精算する
        while progress.rewardedDistance + step <= totalDistance {
            progress.rewardedDistance += step
            character.points += 1
            earned += 1
        }
        return earned
    }
    
    // 2つの日付が同じ日かどうか判定
    private static func isSameDay(_ date1: Date?, _ date2: Date) -> Bool {
        guard let date1 = date1 else { return false }
        return Calendar.current.isDate(date1, inSameDayAs: date2)
    }
    
    // ── 以下、表示用（ポイントは付与しない）──

    // ログインボーナスを今日もう受け取ったか
    static func loginBonusClaimed(progress: GameProgress) -> Bool {
        isSameDay(progress.lastLoginBonusDate, Date())
    }

    // ランニング達成を今日もう受け取ったか
    static func runBonusClaimed(progress: GameProgress) -> Bool {
        isSameDay(progress.lastRunBonusDate, Date())
    }

    // 次の距離達成まであと何メートルか
    static func distanceToNextMilestone(progress: GameProgress, totalDistance: Double) -> Double {
        let step: Double = 3000
        let next = progress.rewardedDistance + step
        return max(0, next - totalDistance)
    }
}
