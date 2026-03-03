//
//  SettingsView.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  Settings view with calculation logic display
//

import SwiftUI

/// 設定画面
struct SettingsView: View {
    @State private var healthKitStatus: String = "確認中..."
    @State private var gasStatus: String = "確認中..."
    @State private var healthKitDetails: [String] = []
    @State private var isCheckingGAS: Bool = false

    var body: some View {
        NavigationView {
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

            // 計算ロジック
            Section(header: Text("計算ロジック")) {
                DisclosureGroup("SubjStage（主観）") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("= 0.7 × median + 0.3 × maxAbs")
                            .font(.caption.monospaced())
                        Text("入力: 気分(総合), ①気分, ②考え, ③身体, ④行動")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("medianは中央値、maxAbsは絶対値最大の値")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                DisclosureGroup("ObjStage（客観）") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("= 重み付き平均（各ドメインのstage × weight）")
                            .font(.caption.monospaced())

                        Group {
                            logicRow("睡眠", "w:4", "<5h→-3, 5-6h→-1, 6-9h→0, 9-10h→-1, >10h→-3")
                            logicRow("歩数", "w:3", "<1k→-3, 1-3k→-2, 3-5k→-1, 5-12k→0, 12-20k→+1, >20k→+3")
                            logicRow("消費kcal", "w:3", "<100→-2, 100-200→-1, 200-500→0, 500-800→+1, >800→+2")
                            logicRow("摂取kcal", "w:3", "≤1000→+2（躁）, ≥3000→-2（鬱）")
                            logicRow("Thinking", "w:2", "OpenAI分析 -5〜+5")
                            logicRow("Calendar", "w:2", "0-2件→0, 3-5件→+1, 6+件→+2")
                        }
                    }
                    .padding(.vertical, 4)
                }

                DisclosureGroup("NetStage") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("= 0.5 × SubjStage + 0.5 × ObjStage")
                            .font(.caption.monospaced())
                        Text("範囲: -5 〜 +5（四捨五入・クランプ）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                DisclosureGroup("Danger (0-5)") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("累積ポイント制（0-5にクランプ）")
                            .font(.caption.monospaced())

                        Group {
                            dangerRow("飲酒", "1杯→+3pt, 2杯→+4pt, 3+杯→+5pt")
                            dangerRow("服薬漏れ", "片方→+1pt, 両方→+2pt")
                            dangerRow("マインドフルネス", "10分以上→-3pt（軽減）")
                            dangerRow("Gap≥2", "+1pt")
                            dangerRow("|NetStage|≥4", "+1pt")
                        }
                    }
                    .padding(.vertical, 4)
                }

                DisclosureGroup("RiskColor") {
                    VStack(alignment: .leading, spacing: 4) {
                        riskColorRow("Green", "Danger<1 & |Net|<1")
                        riskColorRow("Lime", "Danger≥1 or |Net|≥1")
                        riskColorRow("Yellow", "Danger≥2 or |Net|≥2")
                        riskColorRow("Orange", "Danger≥3 or |Net|≥3")
                        riskColorRow("Red", "Danger≥4 or |Net|≥4")
                        riskColorRow("DarkRed", "Danger≥5")
                    }
                    .padding(.vertical, 4)
                }
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
                HStack {
                    Text("仕様書")
                    Spacer()
                    Text("Vol.8 Phase1")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 通知設定
            Section(header: Text("通知")) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.orange)
                    Text("毎朝8:00にローカル通知")
                        .font(.subheadline)
                    Spacer()
                    Text("ON")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                HStack {
                    Image(systemName: "message.fill")
                        .foregroundColor(.green)
                    Text("LINE Messaging API")
                        .font(.subheadline)
                    Spacer()
                    Text("GAS設定")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 履歴データ管理
            Section(header: Text("データ管理")) {
                HStack {
                    Text("保存済み履歴")
                    Spacer()
                    Text("\(HistoryStore.shared.records.count) 件")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await checkHealthKit()
            await checkGAS()
        }
    }

    // MARK: - ヘルパービュー

    private func logicRow(_ domain: String, _ weight: String, _ logic: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(domain)
                    .font(.caption.weight(.medium))
                Text("(\(weight))")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            Text(logic)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func dangerRow(_ label: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.caption)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption.weight(.medium))
                Text(desc)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func riskColorRow(_ color: String, _ condition: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(riskColor(color))
                .frame(width: 10, height: 10)
            Text(color)
                .font(.caption.weight(.medium))
                .frame(width: 60, alignment: .leading)
            Text(condition)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func riskColor(_ name: String) -> Color {
        switch name {
        case "Green": return .green
        case "Lime": return .mint
        case "Yellow": return .yellow
        case "Orange": return .orange
        case "Red": return .red
        case "DarkRed": return .red
        default: return .gray
        }
    }

    // MARK: - チェック関数

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
