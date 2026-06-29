//
//  HomeView.swift
//  Myapp2
//
//  Created by  KoudaTakuma       on 2026/06/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @ObservedObject var store: RunRecordStore
    @ObservedObject var profileStore: UserProfileStore
    @Query private var characters: [GameCharacter]
    @Query private var progresses: [GameProgress]
    
    @State private var earnedMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // あいさつ
                    VStack(alignment: .leading, spacing: 4) {
                        Text("おかえりなさい")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(profileStore.displayName.isEmpty ? "ランナー" : profileStore.displayName)
                            .font(.largeTitle).bold()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // メインカード（累計距離）
                    VStack(spacing: 8) {
                        Text("累計距離")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                        Text(String(format: "%.2f km", store.totalDistance / 1000))
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(
                        LinearGradient(colors: [.blue, .cyan],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .cornerRadius(20)
                    
                    // 統計グリッド（2列）
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        statCard(title: "ラン回数", value: "\(store.runCount)", unit: "回", icon: "figure.run", color: .green)
                        statCard(title: "累計時間", value: timeString(store.totalTime), unit: "", icon: "clock.fill", color: .orange)
                        statCard(title: "消費カロリー", value: String(format: "%.0f", store.totalCalories), unit: "kcal", icon: "flame.fill", color: .red)
                        statCard(title: "最長距離", value: String(format: "%.2f", store.longestDistance / 1000), unit: "km", icon: "trophy.fill", color: .yellow)
                    }
                    
                    // 平均ペース
                    if store.averagePace > 0 {
                        HStack {
                            Image(systemName: "speedometer")
                                .foregroundColor(.purple)
                            Text("平均ペース")
                                .font(.headline)
                            Spacer()
                            Text(paceString(store.averagePace))
                                .font(.title3).bold()
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
                    }
                    // ミッション一覧
                    if let progress = progresses.first {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ミッション")
                                .font(.headline)
                            
                            missionRow(
                                title: "ログインする",
                                reward: "+1 pt",
                                done: MissionManager.loginBonusClaimed(progress: progress),
                                hint: "アプリを開く"
                            )
                            
                            missionRow(
                                title: "ランニング達成",
                                reward: "+2 pt",
                                done: MissionManager.runBonusClaimed(progress: progress),
                                hint: "1km以上走る"
                            )
                            
                            // 距離達成（こちらは毎回貯まるので「あと○m」を表示）
                            let remain = MissionManager.distanceToNextMilestone(
                                progress: progress, totalDistance: store.totalDistance
                            )
                            missionRow(
                                title: "距離達成",
                                reward: "+1 pt",
                                done: false,
                                hint: String(format: "次まであと %.0f m", remain)
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
                    }
                }
                .padding()
            }
            .navigationTitle("ホーム")
            .onAppear {
                checkMissions()
            }
            .alert("ミッション達成！", isPresented: Binding(
                get: { earnedMessage != nil },
                set: { if !$0 { earnedMessage = nil } }
            )) {
                Button("OK") { earnedMessage = nil }
            } message: {
                Text(earnedMessage ?? "")
            }
        }
    }
    
    // 統計カード1枚
    private func statCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2).bold()
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
    }
    
    // 秒 → "1h 23m" 形式
    private func timeString(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
    
    // 秒/km → "5'30\"" 形式
    private func paceString(_ pace: Double) -> String {
        let m = Int(pace) / 60
        let s = Int(pace) % 60
        return String(format: "%d'%02d\" /km", m, s)
    }
    
    // ミッション1行
    private func missionRow(title: String, reward: String, done: Bool, hint: String) -> some View {
        HStack {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundColor(done ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline).bold()
                Text(done ? "達成済み" : hint)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(reward)
                .font(.subheadline).bold()
                .foregroundColor(.blue)
        }
    }
    
    // ログイン＆距離ミッションをチェック
    private func checkMissions() {
        // キャラと進行データを用意（無ければ作る）
        let character = characters.first ?? {
            let new = GameCharacter()
            context.insert(new)
            return new
        }()
        let progress = progresses.first ?? {
            let new = GameProgress()
            context.insert(new)
            return new
        }()
        
        var earned = 0
        earned += MissionManager.checkLoginBonus(character: character, progress: progress)
        earned += MissionManager.checkDistanceMilestone(
            character: character, progress: progress, totalDistance: store.totalDistance
        )
        
        if earned > 0 {
            try? context.save()
            earnedMessage = "\(earned) ポイント獲得しました！"
        }
    }
}
