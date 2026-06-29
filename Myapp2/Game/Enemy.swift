import Foundation

struct Enemy: Identifiable {
    let id = UUID()
    let name: String
    var hp: Int          // 現在HP（戦闘中に減る）
    let maxHP: Int
    let attack: Int
    let defense: Int
    let expReward: Int   // 倒したときの経験値
    
    init(name: String, maxHP: Int, attack: Int, defense: Int, expReward: Int) {
        self.name = name
        self.hp = maxHP
        self.maxHP = maxHP
        self.attack = attack
        self.defense = defense
        self.expReward = expReward
    }
}

// 敵の種類（仮データ）
enum EnemyData {
    static let slime = Enemy(name: "スライム", maxHP: 30, attack: 8, defense: 2, expReward: 20)
    static let goblin = Enemy(name: "ゴブリン", maxHP: 50, attack: 12, defense: 4, expReward: 35)
    static let boss = Enemy(name: "ドラゴン", maxHP: 120, attack: 20, defense: 8, expReward: 100)
}
