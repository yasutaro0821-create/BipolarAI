//
//  DashboardView.swift
//  BipolarAI
//
//  Created on 2026-03-04
//  Home hub — date selector, HealthKit data, evaluation, AI feedback, coping
//

import SwiftUI
import Charts

/// ダッシュボード（ホーム画面）
struct DashboardView: View {
    // 日付選択
    @State private var selectedDateOption: RecordDateOption = .yesterday
    @State private var customDate: Date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()

    // データ
    @State private var healthData: HealthKitData?
    @State private var dailyTrend: [DailyHealthData] = []
    @State private var lastResult: CalculationResult?
    @State private var isLoading = true

    /// 表示対象日
    private var targetDate: Date {
        selectedDateOption.date() ?? Calendar.current.startOfDay(for: customDate)
    }

    /// 対象日の表示テキスト
    private var dateDisplay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日（E）"
        return formatter.string(from: targetDate)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    // ① 日付セレクタ
                    dateSelector

                    // ② HealthKit データ
                    if isLoading {
                        ProgressView("データ取得中...")
                            .padding()
                    } else {
                        healthDataSection
                    }

                    // ③ 評価セクション
                    if let result = lastResult {
                        evaluationSection(result)
                        aiFeedbackSection(result)
                        gapSection(result)
                        driversSection(result)
                        copingSection(result)
                    } else {
                        noEvaluationView
                    }

                    // ④ 7日間トレンド
                    if !dailyTrend.isEmpty {
                        trendSection
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .navigationTitle("ホーム")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
            .onChange(of: selectedDateOption) { _ in
                Task { await loadData() }
            }
            .onChange(of: customDate) { _ in
                if selectedDateOption == .custom {
                    Task { await loadData() }
                }
            }
        }
    }

    // MARK: - 日付セレクタ

    private var dateSelector: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text(dateDisplay)
                    .font(.headline)
                Spacer()
                Text(greetingMessage())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 6) {
                ForEach([RecordDateOption.yesterday, .today, .twoDaysAgo, .threeDaysAgo], id: \.self) { option in
                    Button(action: { selectedDateOption = option }) {
                        Text(option.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(selectedDateOption == option ? Color.blue.opacity(0.15) : Color.gray.opacity(0.08))
                            .foregroundColor(selectedDateOption == option ? .blue : .secondary)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.04))
        .cornerRadius(10)
    }

    // MARK: - HealthKit データ

    private var healthDataSection: some View {
        VStack(spacing: 8) {
            SectionHeader(title: "ヘルスケアデータ", icon: "heart.fill", color: .red)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                MetricTile(label: "睡眠", value: healthData?.formattedSleep() ?? "—", icon: "bed.double.fill", color: .indigo)
                MetricTile(label: "歩数", value: healthData?.formattedSteps() ?? "—", icon: "figure.walk", color: .green)
                MetricTile(label: "消費kcal", value: healthData?.formattedActiveEnergy() ?? "—", icon: "flame.fill", color: .orange)
                MetricTile(label: "摂取kcal", value: healthData?.formattedIntakeEnergy() ?? "—", icon: "fork.knife", color: .yellow)
                MetricTile(label: "マインドフルネス", value: healthData?.formattedMindfulness() ?? "—", icon: "brain.head.profile", color: .purple)
                MetricTile(label: "飲酒", value: healthData?.formattedAlcohol() ?? "—", icon: "wineglass.fill", color: alcoholColor())
                MetricTile(label: "体重", value: healthData?.formattedWeight() ?? "—", icon: "scalemass.fill", color: .teal)
                MetricTile(label: "仮眠", value: healthData?.formattedNap() ?? "—", icon: "zzz", color: .cyan)
            }
        }
    }

    // MARK: - 評価セクション

    private func evaluationSection(_ result: CalculationResult) -> some View {
        VStack(spacing: 10) {
            SectionHeader(title: "評価", icon: "chart.bar.fill", color: .blue)

            // 総合スコア + 注意レベル + 状態
            HStack(spacing: 12) {
                // 総合スコア
                EvalCard(
                    title: "総合スコア",
                    subtitle: "NetStage",
                    value: "\(result.net_stage >= 0 ? "+" : "")\(result.net_stage)",
                    color: stageColor(result.net_stage),
                    explanation: stageExplanation(result.net_stage)
                )

                // 注意レベル
                EvalCard(
                    title: "注意レベル",
                    subtitle: "Danger",
                    value: "\(result.danger)/5",
                    color: dangerColor(result.danger),
                    explanation: dangerExplanation(result.danger)
                )

                // 状態
                VStack(spacing: 4) {
                    Text("状態")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)

                    Circle()
                        .fill(riskSwiftUIColor(result.risk_color))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                    Text(riskLabel(result.risk_color))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(riskSwiftUIColor(result.risk_color))
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(riskSwiftUIColor(result.risk_color).opacity(0.06))
                .cornerRadius(10)
            }
        }
    }

    // MARK: - AIフィードバック

    private func aiFeedbackSection(_ result: CalculationResult) -> some View {
        Group {
            if let feedback = result.ai_feedback, !feedback.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("AIからのフィードバック")
                            .font(.subheadline.weight(.semibold))
                    }
                    Text(feedback)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.06))
                .cornerRadius(10)
            }
        }
    }

    // MARK: - 主観 vs 客観 ズレ

    private func gapSection(_ result: CalculationResult) -> some View {
        VStack(spacing: 8) {
            SectionHeader(title: "主観 vs 客観", icon: "arrow.left.arrow.right", color: .indigo)

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("主観評価")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(result.subj_stage >= 0 ? "+" : "")\(result.subj_stage)")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.blue)
                    Text("自分の感覚")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text("ズレ")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(result.gap)")
                        .font(.title2.weight(.bold))
                        .foregroundColor(result.gap >= 2 ? .orange : .gray)
                    Text(result.gap >= 2 ? "要注意" : "正常")
                        .font(.system(size: 9))
                        .foregroundColor(result.gap >= 2 ? .orange : .green)
                }

                VStack(spacing: 4) {
                    Text("客観評価")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(result.obj_stage >= 0 ? "+" : "")\(result.obj_stage)")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.green)
                    Text("HealthKit等")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(12)
            .background(Color.gray.opacity(0.04))
            .cornerRadius(10)

            if result.gap >= 2 {
                Text("💡 主観と客観のズレが\(result.gap)あります。自分の感覚と実際の体調データに差があるかもしれません。")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - 主な要因

    private func driversSection(_ result: CalculationResult) -> some View {
        let validDrivers = result.top_drivers.filter { !$0.description.isEmpty }
        return Group {
            if !validDrivers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "主な要因", icon: "arrow.up.right.circle.fill", color: .blue)

                    ForEach(Array(validDrivers.enumerated()), id: \.offset) { index, driver in
                        HStack(spacing: 8) {
                            Text("\(index + 1)")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.white)
                                .frame(width: 18, height: 18)
                                .background(Color.blue)
                                .cornerRadius(9)
                            Text(driver.description)
                                .font(.subheadline)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.06))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - コーピング提案

    private func copingSection(_ result: CalculationResult) -> some View {
        let validCoping = result.coping3.filter { !$0.text.isEmpty }
        return Group {
            if !validCoping.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "対処アクション", icon: "lightbulb.fill", color: .green)

                    ForEach(Array(validCoping.enumerated()), id: \.offset) { index, coping in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                                .font(.subheadline)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(coping.text)
                                    .font(.subheadline)
                                if !coping.domain.isEmpty {
                                    Text(coping.domain)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.06))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - 評価なし

    private var noEvaluationView: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.and.pencil")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("\(dateDisplay)の評価はまだありません")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("「記録」タブから気分を記録してください")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.06))
        .cornerRadius(12)
    }

    // MARK: - 7日間トレンド

    @ViewBuilder
    private var trendSection: some View {
        if #available(iOS 16.0, *) {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "7日間のトレンド", icon: "chart.xyaxis.line", color: .indigo)

                // 歩数バーチャート
                let stepsData = dailyTrend.filter { $0.steps != nil }
                if !stepsData.isEmpty {
                    TrendChartCard(title: "歩数") {
                        Chart {
                            ForEach(dailyTrend) { data in
                                BarMark(
                                    x: .value("日付", data.dateString),
                                    y: .value("歩数", data.steps ?? 0)
                                )
                                .foregroundStyle(Color.green.gradient)
                                .cornerRadius(3)
                            }
                        }
                        .frame(height: 100)
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                if let v = value.as(Int.self) {
                                    AxisValueLabel { Text("\(v/1000)k").font(.caption2) }
                                }
                                AxisGridLine()
                            }
                        }
                    }
                }

                // 睡眠ラインチャート
                let sleepData = dailyTrend.filter { $0.sleep_min != nil }
                if !sleepData.isEmpty {
                    TrendChartCard(title: "睡眠時間") {
                        Chart {
                            RectangleMark(yStart: .value("L", 6.0), yEnd: .value("H", 9.0))
                                .foregroundStyle(Color.green.opacity(0.08))
                            ForEach(dailyTrend) { data in
                                let h = Double(data.sleep_min ?? 0) / 60.0
                                LineMark(x: .value("日", data.dateString), y: .value("h", h))
                                    .foregroundStyle(Color.indigo)
                                    .symbol(Circle())
                            }
                        }
                        .frame(height: 100)
                    }
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

        // 対象日のHealthKitデータ取得
        do {
            healthData = try await HealthKitService.shared.fetchData(for: targetDate)
        } catch {
            print("⚠️ Dashboard HealthKit error: \(error)")
        }

        // 7日間トレンド
        do {
            dailyTrend = try await HealthKitService.shared.fetchDailyData(days: 7)
        } catch {
            print("⚠️ Dashboard trend error: \(error)")
        }

        isLoading = false
    }

    // MARK: - ヘルパー

    private func greetingMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "おはようございます"
        case 12..<17: return "こんにちは"
        default: return "こんばんは"
        }
    }

    private func stageColor(_ stage: Int) -> Color {
        if stage > 0 { return .red }
        if stage < 0 { return .blue }
        return .gray
    }

    private func stageExplanation(_ stage: Int) -> String {
        switch stage {
        case -5...(-4): return "強い鬱傾向"
        case -3...(-2): return "鬱傾向"
        case -1: return "やや鬱"
        case 0: return "安定"
        case 1: return "やや躁"
        case 2...3: return "躁傾向"
        default: return "強い躁傾向"
        }
    }

    private func dangerColor(_ danger: Int) -> Color {
        switch danger {
        case 0...1: return .green
        case 2: return .yellow
        case 3: return .orange
        default: return .red
        }
    }

    private func dangerExplanation(_ danger: Int) -> String {
        switch danger {
        case 0: return "リスクなし"
        case 1: return "軽度"
        case 2: return "中度"
        case 3: return "高め"
        case 4: return "高リスク"
        default: return "緊急"
        }
    }

    private func riskSwiftUIColor(_ riskColor: String) -> Color {
        switch riskColor {
        case "Green": return .green
        case "Lime": return .mint
        case "Yellow": return .yellow
        case "Orange": return .orange
        case "Red", "DarkRed": return .red
        default: return .gray
        }
    }

    private func riskLabel(_ riskColor: String) -> String {
        switch riskColor {
        case "Green": return "安全"
        case "Lime": return "注意"
        case "Yellow": return "要観察"
        case "Orange": return "危険"
        case "Red": return "高リスク"
        case "DarkRed": return "緊急"
        default: return "—"
        }
    }

    private func alcoholColor() -> Color {
        guard let d = healthData?.alcohol_drinks else { return .gray }
        if d == 0 { return .green }
        if d <= 2 { return .yellow }
        return .red
    }
}

// MARK: - 共通コンポーネント

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.subheadline)
            Text(title)
                .font(.subheadline.weight(.bold))
            Spacer()
        }
    }
}

struct MetricTile: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(color.opacity(0.06))
        .cornerRadius(8)
    }
}

struct EvalCard: View {
    let title: String
    let subtitle: String
    let value: String
    let color: Color
    let explanation: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(color)
            Text(explanation)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(color.opacity(0.8))
            Text(subtitle)
                .font(.system(size: 8))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(color.opacity(0.06))
        .cornerRadius(10)
    }
}

struct TrendChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            content
        }
        .padding(10)
        .background(Color.gray.opacity(0.04))
        .cornerRadius(10)
    }
}
