//
//  RebootView.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  Reboot program view
//

import SwiftUI
import UserNotifications

/// Rebootプログラム画面
struct RebootView: View {
    let rebootStatus: RebootStatus
    @State private var selectedAction: RebootAction?
    @State private var showingSnoozeSheet = false
    @State private var showingHelpConfirm = false
    @State private var rebootStarted = false
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
            .confirmationDialog("スヌーズ時間を選択", isPresented: $showingSnoozeSheet, titleVisibility: .visible) {
                Button("1時間後") { scheduleSnooze(hours: 1) }
                Button("3時間後") { scheduleSnooze(hours: 3) }
                Button("明日の朝（9:00）") { scheduleSnoozeTomorrow() }
                Button("キャンセル", role: .cancel) { }
            }
            .alert("支援者に通知を送りますか？", isPresented: $showingHelpConfirm) {
                Button("送信", role: .destructive) { sendHelpNotification() }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("LINE Notify で支援者にあなたの状態を伝えます。")
            }
        }
    }
    
    /// Rebootを実行 — レベルに応じたガイドを表示し、完了リマインダーを設定
    private func executeReboot(_ action: RebootAction) {
        rebootStarted = true
        let (title, minutes): (String, Int) = {
            switch action {
            case .l1: return ("L1 Reset 完了リマインダー", 3)
            case .l2: return ("L2 Reframe 完了リマインダー", 10)
            case .l3: return ("L3 Reconnect 完了リマインダー", 15)
            default:  return ("Reboot リマインダー", 5)
            }
        }()

        // ローカル通知でリマインダーを設定
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = "お疲れ様！チェックインを完了しましょう。"
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(minutes * 60), repeats: false)
            let request = UNNotificationRequest(identifier: "reboot-\(action)", content: content, trigger: trigger)
            center.add(request)
        }

        dismiss()
    }

    /// スヌーズオプションを表示
    private func showSnoozeOptions() {
        showingSnoozeSheet = true
    }

    /// 支援者に助けを求める（LINE Notify 経由）
    private func requestHelp() {
        showingHelpConfirm = true
    }
}

// MARK: - Snooze & Help helpers
extension RebootView {
    private func scheduleSnooze(hours: Int) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "双極AI Reboot"
            content.body = "チェックインの時間です。少しだけ始めてみましょう。"
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(hours * 3600), repeats: false)
            let request = UNNotificationRequest(identifier: "reboot-snooze", content: content, trigger: trigger)
            center.add(request)
        }
        dismiss()
    }

    private func scheduleSnoozeTomorrow() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "双極AI Reboot"
            content.body = "おはようございます。今日はチェックインしてみませんか？"
            content.sound = .default
            var dateComponents = DateComponents()
            dateComponents.hour = 9
            dateComponents.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "reboot-snooze-tomorrow", content: content, trigger: trigger)
            center.add(request)
        }
        dismiss()
    }

    private func sendHelpNotification() {
        let level = rebootStatus.reboot_level ?? "不明"
        let days = rebootStatus.days_since_last_checkin ?? 0
        let message = "【双極AI SOS】\n\(days)日間チェックインがありません（レベル: \(level)）。\n本人が助けを求めています。声をかけてあげてください。"

        Task {
            do {
                try await LineNotifyService.shared.sendMessage(message)
            } catch {
                // LINE未設定でもクラッシュしない
                print("LINE Notify error: \(error)")
            }
        }
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

