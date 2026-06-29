//
//  CharacterView.swift
//  Myapp2
//
//  Created by  KoudaTakuma       on 2026/06/25.
//
import SwiftUI
import SwiftData

struct CharacterView: View {
    @Environment(\.modelContext) private var context
    @Query private var characters: [GameCharacter]
    
    var body: some View {
        NavigationStack {
            if let character = characters.first {
                statusView(character)
            } else {
                ProgressView()   // キャラ作成中
            }
        }
        .onAppear {
            // キャラがまだいなければ初期キャラを作る
            if characters.isEmpty {
                context.insert(GameCharacter())
            }
        }
    }
    
    // ステータス表示
    private func statusView(_ character: GameCharacter) -> some View {
        Form {
            Section("キャラクター") {
                LabeledContent("名前", value: character.name)
                LabeledContent("レベル", value: "\(character.level)")
            }
            Section("ステータス") {
                LabeledContent("HP", value: "\(character.maxHP)")
                LabeledContent("攻撃力", value: "\(character.attack)")
                LabeledContent("防御力", value: "\(character.defense)")
            }
            Section("経験値") {
                LabeledContent("EXP", value: "\(character.exp) / \(character.expToNextLevel)")
                ProgressView(value: Double(character.exp),
                             total: Double(character.expToNextLevel))
            }
            Section("ポイント") {
                LabeledContent("所持ポイント", value: "\(character.points) pt")
            }
        }
        .navigationTitle("冒険")
    }
}


// GameView用：NavigationStackを外したキャラ画面の中身
struct CharacterContent: View {
    @Environment(\.modelContext) private var context
    @ObservedObject var profileStore: UserProfileStore
    @Query private var characters: [GameCharacter]
    
    var body: some View {
        Group {
            if let character = characters.first {
                statusView(character)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if characters.isEmpty {
                context.insert(GameCharacter())
                try? context.save()
            }
        }
    }
    
    // ステータス表示（カード＋アイコンのデザイン）
    private func statusView(_ character: GameCharacter) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // 上部：キャラ情報カード
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 56, height: 56)
                            Image(systemName: "figure.fencing")
                                .font(.system(size: 26))
                                .foregroundColor(.blue)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profileStore.displayName.isEmpty ? "ランナー" : profileStore.displayName)
                                .font(.title2).bold()
                            Text("レベル \(character.level)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    
                    VStack(spacing: 4) {
                        HStack {
                            Text("EXP")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(character.exp) / \(character.expToNextLevel)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        ProgressView(value: Double(character.exp),
                                     total: Double(character.expToNextLevel))
                        .tint(.green)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray5), lineWidth: 1))
                
                // ステータスのグリッド（2列）
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    statBox(icon: "heart.fill", color: .red, label: "HP", value: "\(character.maxHP)")
                    statBox(icon: "flame.fill", color: .orange, label: "攻撃力", value: "\(character.attack)")
                    statBox(icon: "shield.fill", color: .blue, label: "防御力", value: "\(character.defense)")
                    statBox(icon: "star.circle.fill", color: .yellow, label: "ポイント", value: "\(character.points)")
                }
            }
            .padding()
        }
    }
    
    // ステータス1マス分
    private func statBox(icon: String, color: Color, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2).bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }
}
