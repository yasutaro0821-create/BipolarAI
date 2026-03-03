//
//  SettingsView.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  Settings view
//

import SwiftUI

/// 設定画面
struct SettingsView: View {
    @State private var healthKitStatus: String = "確認中..."
    @State private var gasStatus: String = "確認中..."
    @State private var healthKitDetails: [String] = []
    @State private var isCheckingGAS: Bool = false

    var body: some View {
        Form {
            // HealthKit接続状態
            Section(header: Text("HealthKit 接続状態")) {
                HStack {
                    Image(systemName: healthKitStatus.contains("✅") ? "heart.fill" : "heart.slash")
                        .foregroundColor(healthKitStatus.contains("✅") ? .red : .gray)
                    Text(healthKitStatus)
                        .font(.subheadline)
                }

                if !healthKitDetails.isEmpty {
                    ForEach(healthKitDetails, id: \.self) { detail in
                        Text(detail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button("HealthKitデータを再取得") {
                    Task { await checkHealthKit() }
                }
                .font(.subheadline)
            }

            // GAS接続状態
            Section(header: Text("GASバックエンド接続")) {
                HStack {
                    Image(systemName: gasStatus.contains("✅") ? "cloud.fill" : "cloud.slash")
                        .foregroundColor(gasStatus.contains("✅") ? .blue : .gray)
                    Text(gasStatus)
                        .font(.subheadline)
                }

                Button("接続テスト") {
                    Task { await checkGAS() }
                }
                .font(.subheadline)
                .disabled(isCheckingGAS)
            }

            // アプリ情報
            Section(header: Text("アプリ情報")) {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text(Constants.APP_VERSION)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Bundle ID")
                    Spacer()
                    Text("jp.mt-inn.bipolarai")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 注意事項
            Section(header: Text("通知について")) {
                Text("LINE Notifyは2025年3月にサービス終了しました。将来のアップデートで代替の通知方法を追加予定です。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("設定")
        .task {
            await checkHealthKit()
            await checkGAS()
        }
    }

    /// HealthKit状態チェック
    private func checkHealthKit() async {
        do {
            let data = try await HealthKitService.shared.fetchTodayData()
            var details: [String] = []

            if let steps = data.steps { details.append("歩数: \(steps) 歩") }
            if let sleep = data.sleep_min { details.append("睡眠: \(sleep) 分") }
            if let nap = data.nap_min, nap > 0 { details.append("仮眠: \(nap) 分") }
            if let energy = data.active_energy_kcal { details.append("消費エネルギー: \(energy) kcal") }
            if let intake = data.intake_energy_kcal, intake > 0 { details.append("摂取エネルギー: \(intake) kcal") }
            if let mindful = data.mindfulness_min, mindful > 0 { details.append("マインドフルネス: \(mindful) 分") }
            if let alcohol = data.alcohol_drinks, alcohol > 0 { details.append("飲酒: \(alcohol) 杯") }
            if let weight = data.weight_kg { details.append(String(format: "体重: %.1f kg", weight)) }

            await MainActor.run {
                healthKitStatus = "✅ HealthKit接続済み（\(details.count)項目取得）"
                healthKitDetails = details
            }
        } catch {
            await MainActor.run {
                healthKitStatus = "❌ HealthKit未接続: \(error.localizedDescription)"
                healthKitDetails = []
            }
        }
    }

    /// GAS接続チェック
    private func checkGAS() async {
        await MainActor.run {
            isCheckingGAS = true
            gasStatus = "確認中..."
        }

        do {
            let ok = try await GASService.shared.healthCheck()
            await MainActor.run {
                gasStatus = ok ? "✅ GAS接続OK" : "❌ GAS応答エラー"
                isCheckingGAS = false
            }
        } catch {
            await MainActor.run {
                gasStatus = "❌ GAS接続失敗: \(error.localizedDescription)"
                isCheckingGAS = false
            }
        }
    }
}
