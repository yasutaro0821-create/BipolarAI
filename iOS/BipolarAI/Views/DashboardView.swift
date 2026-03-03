//
//  DashboardView.swift
//  BipolarAI
//
//  Created on 2026-03-04
//  HealthKit infographic dashboard (main tab)
//

import SwiftUI
import Charts

/// ダッシュボード画面（HealthKitインフォグラフィック + 前回結果サマリ）
struct DashboardView: View {
    @State private var healthData: HealthKitData?
    @State private var dailyTrend: [DailyHealthData] = []
    @State private var isLoading = true
    @State private var lastResult: CalculationResult?

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // ① 今日の日付
                    dateHeaderView

                    // ② 前回の結果サマリ
                    if let result = lastResult {
                        lastResultSummaryView(result)
                    }

                    // ③ HealthKit カードグリッド
                    if isLoading {
                        ProgressView("HealthKitデータを取得中...")
                            .padding()
                    } else {
                        healthCardsGridView
                    }

                    // ④ 服薬ステータス
                    medicationStatusView

                    // ⑤ 7日間トレンドグラフ
                    if !dailyTrend.isEmpty {
                        trendChartsView
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .navigationTitle("今日")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }

    // MARK: - 日付ヘッダー

    private var dateHeaderView: some View {
        VStack(spacing: 4) {
            Text(formattedDate())
                .font(.headline)
                .foregroundColor(.primary)
            Text(greetingMessage())
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - 前回の結果サマリ

    private func lastResultSummaryView(_ result: CalculationResult) -> some View {
        VStack(spacing: 8) {
            Text("前回の記録")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("NetStage")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(result.net_stage >= 0 ? "+" : "")\(result.net_stage)")
                        .font(.title3.weight(.bold))
                        .foregroundColor(stageColor(result.net_stage))
                }

                VStack(spacing: 2) {
                    Text("Danger")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(result.danger)")
                        .font(.title3.weight(.bold))
                        .foregroundColor(dangerColor(result.danger))
                }

                VStack(spacing: 2) {
                    Text("Risk")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Circle()
                        .fill(riskSwiftUIColor(result.risk_color))
                        .frame(width: 20, height: 20)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.06))
        .cornerRadius(12)
    }

    // MARK: - HealthKitカードグリッド

    private var healthCardsGridView: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            // 睡眠
            HealthMetricCard(
                title: "睡眠",
                value: healthData?.formattedSleep() ?? "未取得",
                icon: "bed.double.fill",
                color: .indigo,
                status: metricStatus(healthData?.sleep_min),
                trend: dailyTrend.compactMap { $0.sleep_min }.isEmpty ? nil :
                    dailyTrend.map { Double($0.sleep_min ?? 0) }
            )

            // 歩数
            HealthMetricCard(
                title: "歩数",
                value: healthData?.formattedSteps() ?? "未取得",
                icon: "figure.walk",
                color: .green,
                status: metricStatus(healthData?.steps),
                trend: dailyTrend.compactMap { $0.steps }.isEmpty ? nil :
                    dailyTrend.map { Double($0.steps ?? 0) }
            )

            // 消費カロリー
            HealthMetricCard(
                title: "消費カロリー",
                value: healthData?.formattedActiveEnergy() ?? "未取得",
                icon: "flame.fill",
                color: .orange,
                status: metricStatus(healthData?.active_energy_kcal),
                trend: dailyTrend.compactMap { $0.active_energy_kcal }.isEmpty ? nil :
                    dailyTrend.map { Double($0.active_energy_kcal ?? 0) }
            )

            // 摂取カロリー
            HealthMetricCard(
                title: "摂取カロリー",
                value: healthData?.formattedIntakeEnergy() ?? "未取得",
                icon: "fork.knife",
                color: .yellow,
                status: metricStatus(healthData?.intake_energy_kcal)
            )

            // マインドフルネス
            HealthMetricCard(
                title: "マインドフルネス",
                value: healthData?.formattedMindfulness() ?? "未取得",
                icon: "brain.head.profile",
                color: .purple,
                status: metricStatus(healthData?.mindfulness_min),
                trend: dailyTrend.compactMap { $0.mindfulness_min }.isEmpty ? nil :
                    dailyTrend.map { Double($0.mindfulness_min ?? 0) }
            )

            // 飲酒
            HealthMetricCard(
                title: "飲酒",
                value: healthData?.formattedAlcohol() ?? "未取得",
                icon: "wineglass.fill",
                color: .pink,
                status: alcoholStatus(),
                trend: dailyTrend.compactMap { $0.alcohol_drinks }.isEmpty ? nil :
                    dailyTrend.map { Double($0.alcohol_drinks ?? 0) }
            )

            // 体重
            HealthMetricCard(
                title: "体重",
                value: healthData?.formattedWeight() ?? "未設定",
                icon: "scalemass.fill",
                color: .teal,
                status: healthData?.weight_kg != nil ? .available : .missing
            )

            // 仮眠
            HealthMetricCard(
                title: "仮眠",
                value: healthData?.formattedNap() ?? "なし",
                icon: "zzz",
                color: .cyan,
                status: healthData?.nap_min != nil && healthData!.nap_min! > 0 ? .available : .noData
            )
        }
    }

    // MARK: - 服薬ステータス

    private var medicationStatusView: some View {
        let today = todayKey()
        let amTaken = UserDefaults.standard.bool(forKey: "medsAmTaken_\(today)")
        let pmTaken = UserDefaults.standard.bool(forKey: "medsPmTaken_\(today)")

        return VStack(alignment: .leading, spacing: 6) {
            Text("服薬")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: amTaken ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(amTaken ? .green : .gray)
                    Text("AM（朝）")
                        .font(.subheadline)
                    Text(amTaken ? "済み" : "未服用")
                        .font(.caption)
                        .foregroundColor(amTaken ? .green : .secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: pmTaken ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(pmTaken ? .green : .gray)
                    Text("PM（夕）")
                        .font(.subheadline)
                    Text(pmTaken ? "済み" : "未服用")
                        .font(.caption)
                        .foregroundColor(pmTaken ? .green : .secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.06))
        .cornerRadius(12)
    }

    // MARK: - 7日間トレンドグラフ

    @ViewBuilder
    private var trendChartsView: some View {
        if #available(iOS 16.0, *) {
            VStack(alignment: .leading, spacing: 12) {
                // 歩数トレンド
                let stepsData = dailyTrend.filter { $0.steps != nil }
                if !stepsData.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("歩数（7日間）")
                            .font(.subheadline.weight(.semibold))

                        Chart {
                            ForEach(dailyTrend) { data in
                                BarMark(
                                    x: .value("日付", data.dateString),
                                    y: .value("歩数", data.steps ?? 0)
                                )
                                .foregroundStyle(Color.green.gradient)
                                .cornerRadius(4)
                            }
                        }
                        .frame(height: 120)
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                if let intValue = value.as(Int.self) {
                                    AxisValueLabel {
                                        Text("\(intValue / 1000)k")
                                            .font(.caption2)
                                    }
                                }
                                AxisGridLine()
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.04))
                    .cornerRadius(12)
                }

                // 睡眠トレンド
                let sleepData = dailyTrend.filter { $0.sleep_min != nil }
                if !sleepData.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("睡眠時間（7日間）")
                            .font(.subheadline.weight(.semibold))

                        Chart {
                            ForEach(dailyTrend) { data in
                                let hours = Double(data.sleep_min ?? 0) / 60.0
                                LineMark(
                                    x: .value("日付", data.dateString),
                                    y: .value("時間", hours)
                                )
                                .foregroundStyle(Color.indigo)
                                .interpolationMethod(.catmullRom)
                                .symbol(Circle())

                                AreaMark(
                                    x: .value("日付", data.dateString),
                                    y: .value("時間", hours)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.indigo.opacity(0.2), Color.indigo.opacity(0.02)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)
                            }
                        }
                        .frame(height: 120)
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                if let doubleValue = value.as(Double.self) {
                                    AxisValueLabel {
                                        Text(String(format: "%.0fh", doubleValue))
                                            .font(.caption2)
                                    }
                                }
                                AxisGridLine()
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.04))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - データ読み込み

    private func loadData() async {
        isLoading = true

        // 前回の結果をUserDefaultsから読み込み
        if let data = UserDefaults.standard.data(forKey: "lastCalculationResult") {
            lastResult = try? JSONDecoder().decode(CalculationResult.self, from: data)
        }

        // HealthKitデータ取得
        do {
            healthData = try await HealthKitService.shared.fetchTodayData()
        } catch {
            print("⚠️ Dashboard HealthKit today error: \(error)")
        }

        // 7日間トレンドデータ取得
        do {
            dailyTrend = try await HealthKitService.shared.fetchDailyData(days: 7)
        } catch {
            print("⚠️ Dashboard HealthKit trend error: \(error)")
        }

        isLoading = false
    }

    // MARK: - ヘルパー

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日（E）"
        return formatter.string(from: Date())
    }

    private func greetingMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "おはようございます"
        case 12..<17: return "こんにちは"
        default: return "こんばんは"
        }
    }

    private func todayKey() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: Date())
    }

    private func metricStatus(_ value: Int?) -> MetricStatus {
        guard let v = value else { return .missing }
        return v > 0 ? .available : .noData
    }

    private func alcoholStatus() -> MetricStatus {
        guard healthData?.alcohol_drinks != nil else { return .missing }
        return .available  // 0杯でも「取得済み」
    }

    private func stageColor(_ stage: Int) -> Color {
        if stage > 0 { return .red }
        if stage < 0 { return .blue }
        return .gray
    }

    private func dangerColor(_ danger: Int) -> Color {
        switch danger {
        case 0...1: return .green
        case 2: return .yellow
        case 3: return .orange
        default: return .red
        }
    }

    private func riskSwiftUIColor(_ riskColor: String) -> Color {
        switch riskColor {
        case "Green": return .green
        case "Lime": return .mint
        case "Yellow": return .yellow
        case "Orange": return .orange
        case "Red": return .red
        case "DarkRed": return .red
        default: return .gray
        }
    }
}
