//
//  RebootView.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  Reboot program view
//

import SwiftUI

/// Rebootプログラム画面
struct RebootView: View {
    let rebootStatus: RebootStatus
    @State private var selectedAction: RebootAction?
    @Environment(\.dismiss) var dismiss
    
    enum RebootAction {
        case l1  // 3分（Resetだけ）
        case l2  // 5〜10分（Reset＋1行）
        case l3  // 15分（小さな実行＋Done報告）
        case snooze  // スヌーズ
        case help  // 助けて（支援者へ）
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Reboot状態の表示
                VStack(spacing: 12) {
                    Text("Rebootが必要です")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    if let level = rebootStatus.reboot_level {
                        Text("レベル: \(level)")
                            .font(.headline)
                    }
                    
                    if let step = rebootStatus.reboot_step {
                        Text("ステップ: \(step)")
                            .font(.subheadline)
                    }
                    
                    if let days = rebootStatus.days_since_last_checkin {
                        Text("\(days)日間チェックインがありません")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                // アクションボタン
                VStack(spacing: 12) {
                    if let level = rebootStatus.reboot_level {
                        switch level {
                        case "L1":
                            RebootActionButton(
                                title: "L1だけやる（3分）",
                                description: "Resetだけ実行します",
                                color: .blue
                            ) {
                                selectedAction = .l1
                                executeReboot(.l1)
                            }
                            
                        case "L2":
                            RebootActionButton(
                                title: "L2をやる（5〜10分）",
                                description: "Reset＋1行記録",
                                color: .green
                            ) {
                                selectedAction = .l2
                                executeReboot(.l2)
                            }
                            
                        case "L3":
                            RebootActionButton(
                                title: "L3をやる（15分）",
                                description: "小さな実行＋Done報告",
                                color: .purple
                            ) {
                                selectedAction = .l3
                                executeReboot(.l3)
                            }
                            
                        default:
                            EmptyView()
                        }
                    }
                    
                    // スヌーズボタン
                    RebootActionButton(
                        title: "今日は無理（スヌーズ）",
                        description: "後で通知します",
                        color: .gray
                    ) {
                        selectedAction = .snooze
                        showSnoozeOptions()
                    }
                    
                    // 助けてボタン（同意済みの場合のみ）
                    RebootActionButton(
                        title: "助けて（支援者へ）",
                        description: "支援者に通知を送ります",
                        color: .red
                    ) {
                        selectedAction = .help
                        requestHelp()
                    }
                }
                .padding()
            }
            .padding()
            .navigationTitle("Reboot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    /// Rebootを実行
    private func executeReboot(_ action: RebootAction) {
        // TODO: Rebootプログラムを実行
        // 実際の実装では、各レベルのプログラムを実行します
        dismiss()
    }
    
    /// スヌーズオプションを表示
    private func showSnoozeOptions() {
        // TODO: スヌーズ時間を選択するUIを表示
        dismiss()
    }
    
    /// 支援者に助けを求める
    private func requestHelp() {
        // TODO: 支援者に通知を送信
        dismiss()
    }
}

/// Rebootアクションボタン
struct RebootActionButton: View {
    let title: String
    let description: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(color)
            .cornerRadius(12)
        }
    }
}

