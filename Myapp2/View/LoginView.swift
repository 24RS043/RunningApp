//
//  LoginView.swift
//  Myapp2
//
//  Created by  KoudaTakuma       on 2026/06/21.
//

import SwiftUI

struct LoginView: View {
    // AuthManager（ログインの係）を受け取る
    @ObservedObject var authManager: AuthManager

    // 入力された値を覚えておく箱
    @State private var email = ""
    @State private var password = ""

    // エラーメッセージ（あれば赤字で表示する）
    @State private var errorMessage = ""

    // 「新規登録モード」かどうか（false ならログインモード）
    @State private var isSignUpMode = false

    var body: some View {
        VStack(spacing: 20) {

            Text(isSignUpMode ? "新規登録" : "ログイン")
                .font(.largeTitle)
                .bold()

            // メールアドレス入力欄
            TextField("メールアドレス", text: $email)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)  // 自動で大文字にしない
                .keyboardType(.emailAddress)

            // パスワード入力欄（入力が隠れる）
            SecureField("パスワード", text: $password)
                .textFieldStyle(.roundedBorder)

            // エラーがあれば赤字で表示
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            // メインのボタン（ログイン or 新規登録）
            Button(action: handleMainAction) {
                Text(isSignUpMode ? "登録する" : "ログイン")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            // モード切り替え（ログイン ⇄ 新規登録）
            Button(action: {
                isSignUpMode.toggle()
                errorMessage = ""
            }) {
                Text(isSignUpMode ? "ログインに戻る" : "アカウントを作る")
                    .font(.footnote)
            }

            Spacer()
        }
        .padding()
    }

    // ボタンが押されたときの処理
    func handleMainAction() {
        errorMessage = ""  // 前のエラーを消す

        if isSignUpMode {
            // 新規登録
            authManager.signUp(email: email, password: password) { error in
                if let error = error {
                    errorMessage = error
                }
                // 成功したら AuthManager の user が自動で変わり、画面が切り替わる
            }
        } else {
            // ログイン
            authManager.login(email: email, password: password) { error in
                if let error = error {
                    errorMessage = error
                }
            }
        }
    }
}
