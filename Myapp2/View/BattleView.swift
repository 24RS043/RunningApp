//
//  BattleView.swift
//  Myapp2
//
//  Created by  KoudaTakuma       on 2026/06/25.
//

import SwiftUI
import SwiftData

struct BattleView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var battle: BattleManager
    
    // キャラと敵を受け取ってバトルを開始する
    init(character: GameCharacter, enemy: Enemy, playerName: String) {
        _battle = StateObject(wrappedValue: BattleManager(character: character, enemy: enemy, playerName: playerName))
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // 敵エリア（赤背景で囲む）
                VStack(spacing: 10) {
                    Text(battle.enemy.name)
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 90, height: 90)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.red)
                    }
                    
                    enemyHPBar()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.red.opacity(0.08))
                .cornerRadius(16)
                
                // 戦闘ログ（最新3件）
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(battle.logs.suffix(3), id: \.self) { log in
                        Text(log)
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                
                // プレイヤーカード（HP＋SP）
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(battle.playerName)
                            .font(.headline)
                        Spacer()
                        Text("\(battle.playerHP) / \(battle.character.maxHP)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    ProgressView(value: Double(battle.playerHP), total: Double(battle.character.maxHP))
                        .tint(.green)
                    
                    // SPを●で表示
                    HStack(spacing: 6) {
                        Text("SP")
                            .font(.caption)
                            .foregroundColor(.purple)
                        ForEach(0..<battle.maxSP, id: \.self) { i in
                            Circle()
                                .fill(i < battle.playerSP ? Color.purple : Color(.systemGray4))
                                .frame(width: 14, height: 14)
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5), lineWidth: 0.5))
                
                // コマンドボタン（攻撃・防御・スキル）
                HStack(spacing: 8) {
                    battleCommand("攻撃", icon: "burst.fill", color: .blue) { battle.attack() }
                    battleCommand("スキル", icon: "sparkles", color: .purple) { battle.skill() }
                        .disabled(battle.playerSP <= 0)
                        .opacity(battle.playerSP <= 0 ? 0.4 : 1.0)
                }
                .disabled(!battle.isPlayerTurn || battle.isFinished)
                .opacity(battle.isPlayerTurn && !battle.isFinished ? 1.0 : 0.5)
            }
            .padding()
        }
        .alert(battle.didWin ? "勝利！" : "敗北…", isPresented: $battle.isFinished) {
            Button("もどる") {
                if battle.didWin { giveRewards() }
                dismiss()
            }
        } message: {
            Text(battle.didWin
                 ? "EXP +\(battle.enemy.expReward)"
                 : "またチャレンジしよう")
        }
    }
    
    // 敵のHPバー
    private func enemyHPBar() -> some View {
        VStack(spacing: 2) {
            ProgressView(value: Double(battle.enemy.hp), total: Double(battle.enemy.maxHP))
                .tint(.red)
                .frame(width: 200)
            Text("\(battle.enemy.hp) / \(battle.enemy.maxHP)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    // コマンドボタン（アイコン付き・色分け）
    private func battleCommand(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.subheadline).bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
    
    // 勝利時の報酬を反映
    private func giveRewards() {
        let character = battle.character
        character.exp += battle.enemy.expReward
        
        while character.exp >= character.expToNextLevel {
            character.exp -= character.expToNextLevel
            character.level += 1
            character.maxHP += 20
            character.attack += 3
            character.defense += 2
        }
        try? context.save()
    }
}
