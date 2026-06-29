//
//  WorldMapView.swift
//  Myapp2
//
//  Created by  KoudaTakuma       on 2026/06/25.
//

import SwiftUI
import SwiftData

// GameView用：NavigationStackを外したマップ画面の中身
struct WorldMapContent: View {
    @Environment(\.modelContext) private var context
    @ObservedObject var store: RunRecordStore
    @ObservedObject var profileStore: UserProfileStore
    @Query private var characters: [GameCharacter]
    @Query private var progresses: [GameProgress]
    
    @State private var notEnoughPoints = false
    @State private var battleStage: Stage?
    
    private var unlockDistance: Double {
        let saved = progresses.first?.maxReachedDistance ?? 0
        return max(saved, store.totalDistance)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                
                // 紫のヘッダー（累計距離＋所持ポイント）
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("累計距離")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text(String(format: "%.2f km", unlockDistance / 1000))
                            .font(.title2).bold()
                            .foregroundColor(.white)
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text("所持pt")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text("\(characters.first?.points ?? 0)")
                            .font(.title3).bold()
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.18))
                    .cornerRadius(10)
                }
                .padding()
                .background(Color.purple)
                .cornerRadius(16)
                .padding(.bottom, 14)
                
                // ステージ一覧
                ForEach(StageData.all) { stage in
                    let unlocked = stage.isUnlocked(totalDistance: unlockDistance)
                    
                    if unlocked, stage.type != .shop {
                        Button {
                            tryStartBattle(stage)
                        } label: {
                            stageRow(stage)
                        }
                        .buttonStyle(.plain)
                    } else {
                        stageRow(stage)
                    }
                    
                    // ステージ間の線（最後以外）
                    if stage.id < StageData.all.count - 1 {
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 3, height: 18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 35)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            updateProgress()
        }
        .navigationDestination(item: $battleStage) { stage in
            if let character = characters.first {
                BattleView(character: character, enemy: enemy(for: stage),
                           playerName: profileStore.displayName.isEmpty ? "ランナー" : profileStore.displayName)
            }
        }
        .alert("ポイントが足りません", isPresented: $notEnoughPoints) {
            Button("OK") { }
        } message: {
            Text("ミッションをこなしてポイントを貯めよう！")
        }
    }
    
    // ポイントを確認してバトルを開始する
    private func tryStartBattle(_ stage: Stage) {
        guard let character = characters.first else { return }
        let cost = stage.type.requiredPoints
        
        if character.points >= cost {
            character.points -= cost
            try? context.save()
            battleStage = stage
        } else {
            notEnoughPoints = true
        }
    }
    
    private func stageRow(_ stage: Stage) -> some View {
        let unlocked = stage.isUnlocked(totalDistance: unlockDistance)
        
        return HStack(spacing: 12) {
            // アイコンの丸
            ZStack {
                Circle()
                    .fill(unlocked ? color(for: stage.type).opacity(0.15) : Color(.systemGray5))
                    .frame(width: 48, height: 48)
                Image(systemName: unlocked ? stage.type.iconName : "lock.fill")
                    .font(.title3)
                    .foregroundColor(unlocked ? color(for: stage.type) : .gray)
            }
            
            // ステージ名と種類
            VStack(alignment: .leading, spacing: 2) {
                Text("ステージ \(stage.id + 1)")
                    .font(.headline)
                Text(stage.type.label)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 右側：消費ポイント or 解放までの距離
            if unlocked {
                Text("\(stage.type.requiredPoints) pt")
                    .font(.caption).bold()
                    .foregroundColor(color(for: stage.type))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(color(for: stage.type).opacity(0.15))
                    .cornerRadius(20)
            } else {
                Text(String(format: "あと %.0f m", stage.requiredDistance - unlockDistance))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5), lineWidth: 0.5))
        .opacity(unlocked ? 1.0 : 0.55)
    }
    
    private func updateProgress() {
        let progress = progresses.first ?? {
            let new = GameProgress()
            context.insert(new)
            return new
        }()
        
        if store.totalDistance > progress.maxReachedDistance {
            progress.maxReachedDistance = store.totalDistance
            try? context.save()
        }
    }
    
    private func color(for type: StageType) -> Color {
        switch type {
        case .battle: return .blue
        case .shop:   return .green
        case .boss:   return .red
        }
    }
    
    private func enemy(for stage: Stage) -> Enemy {
        switch stage.type {
        case .boss:   return EnemyData.boss
        default:      return EnemyData.goblin
        }
    }
}
