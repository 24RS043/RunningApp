//
//  UserProfileStore.swift
//  MyApp2
//
//  ユーザーのプロフィール（表示名・体重）をFirestoreで管理する係
//

import SwiftUI
import Combine
import FirebaseFirestore

class UserProfileStore: ObservableObject {
    
    // 画面に表示する用のプロフィール情報
    @Published var displayName: String = ""   // 表示名（ニックネーム）
    @Published var weight: Double = 0.0       // 体重(kg)
    
    // 今ログインしているユーザーのID
    var currentUserId: String?
    
    private let db = Firestore.firestore()
    
    // 自分のプロフィールをFirestoreから読み込む
    func load() {
        guard let uid = currentUserId else { return }
        
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("プロフィール読み込みエラー: \(error.localizedDescription)")
                return
            }
            
            // まだ保存がない（初めてのユーザー）場合は空のままにする
            guard let data = snapshot?.data() else {
                return
            }
            
            DispatchQueue.main.async {
                self.displayName = data["displayName"] as? String ?? ""
                self.weight = data["weight"] as? Double ?? 0.0  // ← 1行にまとめる
            }
        }
    }
    
    // 今のプロフィールをFirestoreに保存する
    func save() {
        guard let uid = currentUserId else { return }
        
        db.collection("users").document(uid).setData([
            "displayName": displayName,
            "weight": weight
        ], merge: true) { error in   // merge:true で既存データを壊さず上書き
            if let error = error {
                print("プロフィール保存エラー: \(error.localizedDescription)")
            } else {
                print("プロフィール保存成功")
            }
        }
    }
}
