//
//  AuthManager.swift
//  Myapp2
//
//  Created by  KoudaTakuma       on 2026/06/21.
//

import Foundation
import FirebaseAuth
import Combine

class AuthManager: ObservableObject {

    // 今ログインしているユーザー（ログインしていなければ nil）
    // ログインしているかどうか
    @Published var isLoggedIn: Bool = false

    // ログイン中のユーザーID（記録を誰のものか区別するのに後で使う）
    @Published var userId: String?
    init() {
        // アプリ起動時、すでにログイン済みかどうかを反映する
        let currentUser = Auth.auth().currentUser
        self.isLoggedIn = (currentUser != nil)
        self.userId = currentUser?.uid

        // ログイン状態が変わったら自動で更新する
        Auth.auth().addStateDidChangeListener { _, user in
            self.isLoggedIn = (user != nil)
            self.userId = user?.uid
        }
    }

    // 新規登録（アカウントを作る）
    func signUp(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { _, error in
            if let error = error {
                completion(error.localizedDescription)  // 失敗：エラー文を返す
            } else {
                completion(nil)  // 成功
            }
        }
    }

    // ログイン
    func login(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                completion(error.localizedDescription)
            } else {
                completion(nil)
            }
        }
    }

    // ログアウト
    func logout() {
        try? Auth.auth().signOut()
    }
}
