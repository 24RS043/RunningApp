//
//  GameCharacter.swift
//  Myapp2
//
//  Created by  KoudaTakuma       on 2026/06/25.
//

import Foundation
import SwiftData

@Model
class GameCharacter {
    var name: String        // キャラ名
    var level: Int          // レベル
    var exp: Int            // 経験値
    var maxHP: Int          // 最大HP
    var attack: Int         // 攻撃力（基礎値）
    var defense: Int        // 防御力（基礎値）
    var points: Int         // 所持ポイント

    init(
        name: String = "勇者",
        level: Int = 1,
        exp: Int = 0,
        maxHP: Int = 100,
        attack: Int = 10,
        defense: Int = 5,
        points: Int = 0
    ) {
        self.name = name
        self.level = level
        self.exp = exp
        self.maxHP = maxHP
        self.attack = attack
        self.defense = defense
        self.points = points
    }

    // 次のレベルまでに必要な経験値（仮の計算式・あとで調整可）
    var expToNextLevel: Int {
        level * 100
    }
}
