//
//  BattleManager.swift
//  Myapp2
//
//  Created by  KoudaTakuma       on 2026/06/25.
//

import Foundation
import SwiftUI
import Combine

class BattleManager: ObservableObject {
    @Published var enemy: Enemy
    @Published var playerHP: Int
    @Published var logs: [String] = []      // 戦闘ログ
    @Published var isPlayerTurn = true      // プレイヤーのターンか
    @Published var isFinished = false       // 戦闘終了したか
    @Published var didWin = false           // 勝ったか
    @Published var playerSP: Int            // 残りスキル使用回数
    
    let character: GameCharacter
    let playerName: String
    let maxSP = 3                     // 1戦闘で3回まで
    private var isDefending = false         // 防御中か
    
    init(character: GameCharacter, enemy: Enemy, playerName: String) {
        self.character = character
        self.enemy = enemy
        self.playerName = playerName
        self.playerHP = character.maxHP
        self.playerSP = 3
        logs.append("\(enemy.name) があらわれた！")
    }
    
    // 攻撃
    func attack() {
        guard isPlayerTurn, !isFinished else { return }
        let damage = max(1, character.attack - enemy.defense)
        enemy.hp = max(0, enemy.hp - damage)
        logs.append("\(playerName) の攻撃！ \(damage) のダメージ")
        checkEnemyDefeated()
    }
    
    // 防御（次の敵の攻撃を半減）
    func defend() {
        guard isPlayerTurn, !isFinished else { return }
        isDefending = true
        logs.append("\(playerName) は身をまもっている")
        endPlayerTurn()
    }
    
    /// スキル（SPを1消費して強攻撃）
    func skill() {
        guard isPlayerTurn, !isFinished else { return }

        // SPが足りなければ使えない
        guard playerSP > 0 else {
            logs.append("SPが足りない！")
            return
        }

        playerSP -= 1   // SP消費
        let damage = max(1, Int(Double(character.attack) * 1.5) - enemy.defense)
        enemy.hp = max(0, enemy.hp - damage)
        logs.append("\(playerName) のスキル！ \(damage) のダメージ")
        checkEnemyDefeated()
    }
    
    // 敵が倒れたか確認
    private func checkEnemyDefeated() {
        if enemy.hp <= 0 {
            logs.append("\(enemy.name) をたおした！")
            didWin = true
            isFinished = true
        } else {
            endPlayerTurn()
        }
    }
    
    // プレイヤーのターン終了 → 敵の攻撃
    private func endPlayerTurn() {
        isPlayerTurn = false
        // 少し待ってから敵が攻撃（演出のため）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.enemyAttack()
        }
    }
    
    // 敵の攻撃
    private func enemyAttack() {
        guard !isFinished else { return }
        var damage = max(1, enemy.attack - character.defense)
        if isDefending {
            damage = max(1, damage / 2)   // 防御中は半減
            isDefending = false
        }
        playerHP = max(0, playerHP - damage)
        logs.append("\(enemy.name) の攻撃！ \(damage) のダメージ")
        
        if playerHP <= 0 {
            logs.append("\(playerName) はたおれてしまった…")
            didWin = false
            isFinished = true
        } else {
            isPlayerTurn = true
        }
    }
}
