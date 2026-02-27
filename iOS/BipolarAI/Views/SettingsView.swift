//
//  SettingsView.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  Settings view (LINE Notify token, etc.)
//

import SwiftUI

/// 設定画面
struct SettingsView: View {
    @State private var lineNotifyToken: String = ""
    @State private var showTokenAlert: Bool = false
    @State private var tokenSaved: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("LINE通知設定")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LINE Notify トークン")
                            .font(.headline)
                        
                        Text("LINE Notifyのトークンを設定すると、日次通知と危険度が高い時の通知を受け取れます。")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        SecureField("トークンを入力", text: $lineNotifyToken)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            saveToken()
                        }) {
                            Text("保存")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(lineNotifyToken.isEmpty)
                        
                        if tokenSaved {
                            Text("トークンを保存しました")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("トークンの取得方法")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. LINE Notifyの公式サイトにアクセス")
                        Text("2. ログインして「トークンを発行する」をクリック")
                        Text("3. トークン名を入力（例：「双極AI」）")
                        Text("4. 通知を送信するトークルームを選択")
                        Text("5. 発行されたトークンをコピーして、上記の欄に貼り付け")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                Section(header: Text("その他")) {
                    Link("LINE Notify公式サイト", destination: URL(string: "https://notify-bot.line.me/")!)
                }
            }
            .navigationTitle("設定")
            .onAppear {
                loadToken()
            }
        }
    }
    
    /// トークンを読み込み
    private func loadToken() {
        if let token = UserDefaults.standard.string(forKey: "line_notify_token") {
            lineNotifyToken = token
        }
    }
    
    /// トークンを保存
    private func saveToken() {
        LineNotifyService.shared.setToken(lineNotifyToken)
        tokenSaved = true
        
        // 3秒後にメッセージを消す
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            tokenSaved = false
        }
    }
}

