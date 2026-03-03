//
//  DashboardView.swift
//  BipolarAI
//
//  Created on 2026-03-04
//  HealthKit infographic dashboard (main tab) — vertical full-width layout
//

import SwiftUI
import Charts

/// ダッシュボード画面（縦長フルワイドインフォグラフィック + 前回結果サマリ）
struct DashboardView: View {
    @State private var healthData: HealthKitData?
    @State private var dailyTrend: [DailyHealthData] = []
    @State private var isLoading = true
    @State private var lastResult: CalculationResult?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    // ① 今日の日付
                    dateHeaderView

                    // ② 前回の結果サマリ
                    if let result = lastResult {
                        lastResultSummaryView(result)
                    }

                    // ③ HealthKit メトリクス（縦長1列フルワイド）
                    if isLoading {
                        ProgressView("HealthKitデータを取得中...")
                            .padding()
                    } else {
                        healthMetricsView
                    }

                    // ④ 7日間トレンドグラフ
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

    // MARK: - HealthKit メトリクス（縦長1列フルワイド）

    private var healthMetricsView: some View {
        VStack(spacing: 10) {
            // 睡眠
            FullWidthMetricCard(
                title: "睡眠",
                value: healthData?.formattedSleep() ?? "未取得",
                icon: "bed.double.fill",
                color: .indigo
            ) {
                if let sleepMin = healthData?.sleep_min {
                    SleepProgressBar(minutes: sleepMin)
                }
            }

            // 歩数
            FullWidthMetricCard(
                title: "歩数",
                value: healthData?.formattedSteps() ?? "未取得",
                icon: "figure.walk",
                color: .green
            ) {
                if let steps = healthData?.steps {
                    GoalProgressBar(
                        current: Double(steps),
                        goal: 10000,
                        color: .green,
                        unit: "歩"
                    )
                }
            }

            // 消費カロリー
            FullWidthMetricCard(
                title: "消費カロリー",
                value: healthData?.formattedActiveEnergy() ?? "未取得",
                icon: "flame.fill",
                color: .orange
            ) {
                if let kcal = healthData?.active_energy_kcal {
                    GoalProgressBar(
                        current: Double(kcal),
                        goal: 500,
                        color: .orange,
                        unit: "kcal"
                    )
                }
            }

            // 摂取カロリー
            FullWidthMetricCard(
                title: "摂取カロリー",
                value: healthData?.formattedIntakeEnergy() ?? "未取得",
                icon: "fork.knife",
                color: .yellow
            ) {
                if let kcal = healthData?.intake_energy_kcal {
                    RangeProgressBar(
                        current: Double(kcal),
                        low: 1000,
                        high: 3000,
                        color: .yellow
                    )
                }
            }

            // マインドフルネス
            FullWidthMetricCard(
                title: "マインドフルネス",
                value: healthData?.formattedMindfulness() ?? "未取得",
                icon: "brain.head.profile",
                color: .purple
            ) {
                if let min = healthData?.mindfulness_min {
                    HStack(spacing: 8) {
                        GoalProgressBar(
                            current: Double(min),
                            goal: 10,
                            color: .purple,
                            unit: "分"
                        )
                        if min >= 10 {
                            Text("✓")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple)
                                .cornerRadius(4)
                        }
                    }
                }
            }

            // 飲酒
            FullWidthMetricCard(
                title: "飲酒",
                value: healthData?.formattedAlcohol() ?? "未取得",
                icon: "wineglass.fill",
                color: alcoholLevelColor()
            ) {
                if let drinks = healthData?.alcohol_drinks {
                    AlcoholIndicator(drinks: drinks)
                }
            }

            // 体重
            FullWidthMetricCard(
                title: "体重",
                value: healthData?.formattedWeight() ?? "未設定",
                icon: "scalemass.fill",
                color: .teal
            ) {
                EmptyView()
            }

            // 仮眠
            FullWidthMetricCard(
                title: "仮眠",
                value: healthData?.formattedNap() ?? "なし",
                icon: "zzz",
                color: .cyan
            ) {
                if let nap = healthData?.nap_min, nap > 0 {
                    GoalProgressBar(
                        current: Double(nap),
                        goal: 30,
                        color: .cyan,
                        unit: "分"
                    )
                }
            }
        }
    }

    // MARK: - 7日間トレンドグラフ

    @ViewBuilder
    private var trendChartsView: some View {
        if #available(iOS 16.0, *) {
            VStack(alignment: .leading, spacing: 12) {
                // 歩数トレンド
                let stepsData = dailyTrend.filter { $0.steps != nil }
                if !stepsData.isEmpty {
                    TrendChartCard(title: "歩数（7日間）") {
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
                }

                // 睡眠トレンド
                let sleepData = dailyTrend.filter { $0.sleep_min != nil }
                if !sleepData.isEmpty {
                    TrendChartCard(title: "睡眠時間（7日間）") {
                        Chart {
                            // 正常範囲バンド
                            RectangleMark(
                                yStart: .value("Low", 6.0),
                                yEnd: .value("High", 9.0)
                            )
                            .foregroundStyle(Color.green.opacity(0.08))

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
                }

                // 体重トレンド
                let weightData = dailyTrend.filter { $0.weight_kg != nil }
                if !weightData.isEmpty {
                    TrendChartCard(title: "体重（7日間）") {
                        Chart {
                            ForEach(dailyTrend) { data in
                                if let w = data.weight_kg {
                                    LineMark(
                                        x: .value("日付", data.dateString),
                                        y: .value("kg", w)
                                    )
                                    .foregroundStyle(Color.teal)
                                    .interpolationMethod(.catmullRom)
                                    .symbol(Circle())
                                }
                            }
                        }
                        .frame(height: 100)
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                if let dv = value.as(Double.self) {
                                    AxisValueLabel {
                                        Text(String(format: "%.0f", dv))
                                            .font(.caption2)
                                    }
                                }
                                AxisGridLine()
                            }
                        }
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

    private func alcoholLevelColor() -> Color {
        guard let drinks = healthData?.alcohol_drinks else { return .gray }
        if drinks == 0 { return .green }
        if drinks <= 2 { return .yellow }
        return .red
    }
}

// MARK: - フルワイドメトリクスカード

struct FullWidthMetricCard<Content: View>: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ヘッダー行
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            // コンテンツ（プログレスバーなど）
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [color.opacity(0.08), color.opacity(0.02)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
}

// MARK: - 睡眠プログレスバー

struct SleepProgressBar: View {
    let minutes: Int

    private var hours: Double { Double(minutes) / 60.0 }
    private var isNormal: Bool { hours >= 6 && hours <= 9 }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 12)

                    // 正常範囲マーカー（6-9h）
                    let normalStart = CGFloat(6.0 / 12.0) * geo.size.width
                    let normalEnd = CGFloat(9.0 / 12.0) * geo.size.width
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.green.opacity(0.2))
                        .frame(width: normalEnd - normalStart, height: 12)
                        .offset(x: normalStart)

                    // 実際の値
                    let progress = min(hours / 12.0, 1.0)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isNormal ? Color.indigo : Color.orange)
                        .frame(width: max(geo.size.width * CGFloat(progress), 4), height: 12)
                }
            }
            .frame(height: 12)

            // ラベル
            HStack {
                Text("0h")
                Spacer()
                Text("6h")
                    .foregroundColor(.green)
                Spacer()
                Text("9h")
                    .foregroundColor(.green)
                Spacer()
                Text("12h")
            }
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.secondary)
        }
    }
}

// MARK: - 目標プログレスバー

struct GoalProgressBar: View {
    let current: Double
    let goal: Double
    let color: Color
    let unit: String

    private var progress: Double { min(current / goal, 1.5) }
    private var achieved: Bool { current >= goal }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 10)

                    // 目標ライン
                    let goalPos = min(1.0 / 1.5, 1.0) * geo.size.width
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 1.5, height: 14)
                        .offset(x: goalPos)

                    // プログレス
                    let width = max(geo.size.width * CGFloat(progress / 1.5), 4)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(achieved ? color : color.opacity(0.6))
                        .frame(width: min(width, geo.size.width), height: 10)
                }
            }
            .frame(height: 14)

            // ラベル
            HStack {
                Text("0")
                Spacer()
                Text("目標: \(Int(goal))\(unit)")
                    .foregroundColor(achieved ? color : .secondary)
            }
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.secondary)
        }
    }
}

// MARK: - 範囲プログレスバー

struct RangeProgressBar: View {
    let current: Double
    let low: Double
    let high: Double
    let color: Color

    private var isInRange: Bool { current >= low && current <= high }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                let maxVal = high * 1.3
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 10)

                    // 正常範囲
                    let lowX = CGFloat(low / maxVal) * geo.size.width
                    let highX = CGFloat(high / maxVal) * geo.size.width
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.green.opacity(0.2))
                        .frame(width: highX - lowX, height: 10)
                        .offset(x: lowX)

                    // 現在値マーカー
                    let pos = CGFloat(min(current / maxVal, 1.0)) * geo.size.width
                    Circle()
                        .fill(isInRange ? Color.green : Color.orange)
                        .frame(width: 12, height: 12)
                        .offset(x: max(pos - 6, 0))
                }
            }
            .frame(height: 12)

            HStack {
                Text("\(Int(low))")
                Spacer()
                Text(isInRange ? "正常範囲内" : "範囲外")
                    .foregroundColor(isInRange ? .green : .orange)
                Spacer()
                Text("\(Int(high))")
            }
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.secondary)
        }
    }
}

// MARK: - 飲酒インジケータ

struct AlcoholIndicator: View {
    let drinks: Int

    private var levelColor: Color {
        if drinks == 0 { return .green }
        if drinks <= 2 { return .yellow }
        return .red
    }

    private var levelText: String {
        if drinks == 0 { return "飲酒なし 👍" }
        if drinks <= 2 { return "適量" }
        return "注意"
    }

    var body: some View {
        HStack(spacing: 8) {
            // グラスアイコン
            HStack(spacing: 2) {
                ForEach(0..<min(drinks, 5), id: \.self) { _ in
                    Image(systemName: "wineglass.fill")
                        .font(.system(size: 12))
                        .foregroundColor(levelColor)
                }
            }

            Spacer()

            Text(levelText)
                .font(.caption2.weight(.medium))
                .foregroundColor(levelColor)
        }
    }
}

// MARK: - トレンドチャートカード

struct TrendChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            content
        }
        .padding(12)
        .background(Color.gray.opacity(0.04))
        .cornerRadius(12)
    }
}
