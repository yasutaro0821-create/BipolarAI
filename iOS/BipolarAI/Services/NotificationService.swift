//
//  NotificationService.swift
//  BipolarAI
//
//  Created on 2026-03-04
//  Local notification service for morning reminders
//

import Foundation
import UserNotifications

/// ローカル通知サービス（朝8時リマインダー）
class NotificationService {
    static let shared = NotificationService()

    private let reminderIdentifier = "morning_checkin_reminder"

    private init() {}

    /// 通知権限をリクエスト
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("✅ 通知権限が許可されました")
                scheduleMorningReminder()
            } else {
                print("⚠️ 通知権限が拒否されました")
            }
        } catch {
            print("⚠️ 通知権限エラー: \(error)")
        }
    }

    /// 毎朝8:00にリマインダーをスケジュール
    func scheduleMorningReminder() {
        let content = UNMutableNotificationContent()
        content.title = "双極AI"
        content.body = "おはようございます！今日の気分チェックインをしましょう。"
        content.sound = .default

        // 毎朝8:00
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ 通知スケジュールエラー: \(error)")
            } else {
                print("✅ 毎朝8:00の通知をスケジュールしました")
            }
        }
    }

    /// 今日のリマインダーをキャンセル（チェックイン済み）
    func cancelTodayReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
        // 再スケジュール（翌日分）
        scheduleMorningReminder()
    }
}
