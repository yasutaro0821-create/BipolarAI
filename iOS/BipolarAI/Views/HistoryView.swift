//
//  HistoryView.swift
//  BipolarAI
//
//  Created on 2026-03-04
//  History view with trend graphs and record list
//

import SwiftUI
import Charts

/// 履歴画面（トレンドグラフ + 記録一覧）
struct HistoryView: View {
    @ObservedObject private var store = HistoryStore.shared
    @State private var selectedPeriod: Period = .week

    enum Period: String, CaseIterable {
        case week = "7日"
        case month = "30日"
        case all = "全て"
    }

    private var filteredRecords: [HistoryRecord] {
        let sorted = store.records.sorted { $0.date < $1.date }
        switch selectedPeriod {
        case .week: return Array(sorted.suffix(7))
        case .month: return Array(sorted.suffix(30))
        case .all: return sorted
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 期間選択
                    Picker("期間", selection: $selectedPeriod) {
                        ForEach(Period.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if filteredRecords.isEmpty {
                        emptyStateView
                    } else {
                        // トレンドグラフ
                        trendGraphsView

                        // 記録一覧
                        recordListView
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - 空状態

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.4))
            Text("まだ記録がありません")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("「記録」タブから気分を記録すると\nここに履歴が表示されます")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    // MARK: - トレンドグラフ

    @ViewBuilder
    private var trendGraphsView: some View {
        if #available(iOS 16.0, *) {
            VStack(spacing: 12) {
                // NetStage トレンド
                VStack(alignment: .leading, spacing: 4) {
                    Text("NetStage 推移")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal)

                    Chart {
                        // ゼロライン
                        RuleMark(y: .value("Zero", 0))
                            .foregroundStyle(Color.gray.opacity(0.3))
                            .lineStyle(StrokeStyle(dash: [5, 3]))

                        ForEach(filteredRecords) { record in
                            LineMark(
                                x: .value("日付", shortDate(record.date)),
                                y: .value("NetStage", record.net_stage)
                            )
                            .foregroundStyle(Color.blue)
                            .interpolationMethod(.catmullRom)
                            .symbol(Circle())
                            .symbolSize(30)

                            PointMark(
                                x: .value("日付", shortDate(record.date)),
                                y: .value("NetStage", record.net_stage)
                            )
                            .foregroundStyle(stageColor(record.net_stage))
                            .symbolSize(40)
                        }
                    }
                    .frame(height: 150)
                    .chartYScale(domain: -5...5)
                    .chartYAxis {
                        AxisMarks(values: [-5, -3, 0, 3, 5]) { value in
                            AxisValueLabel()
                            AxisGridLine()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.04))
                .cornerRadius(12)
                .padding(.horizontal, 12)

                // Danger トレンド
                VStack(alignment: .leading, spacing: 4) {
                    Text("Danger レベル推移")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal)

                    Chart {
                        ForEach(filteredRecords) { record in
                            BarMark(
                                x: .value("日付", shortDate(record.date)),
                                y: .value("Danger", record.danger)
                            )
                            .foregroundStyle(dangerGradient(record.danger))
                            .cornerRadius(4)
                        }
                    }
                    .frame(height: 120)
                    .chartYScale(domain: 0...5)
                    .chartYAxis {
                        AxisMarks(values: [0, 1, 2, 3, 4, 5]) { value in
                            AxisValueLabel()
                            AxisGridLine()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.04))
                .cornerRadius(12)
                .padding(.horizontal, 12)

                // 歩数トレンド（データがある場合）
                let stepsRecords = filteredRecords.filter { $0.steps != nil }
                if !stepsRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("歩数推移")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal)

                        Chart {
                            ForEach(filteredRecords) { record in
                                BarMark(
                                    x: .value("日付", shortDate(record.date)),
                                    y: .value("歩数", record.steps ?? 0)
                                )
                                .foregroundStyle(Color.green.gradient)
                                .cornerRadius(4)
                            }
                        }
                        .frame(height: 120)
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.04))
                    .cornerRadius(12)
                    .padding(.horizontal, 12)
                }

                // 睡眠トレンド（データがある場合）
                let sleepRecords = filteredRecords.filter { $0.sleep_min != nil }
                if !sleepRecords.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("睡眠時間推移")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal)

                        Chart {
                            ForEach(filteredRecords) { record in
                                let hours = Double(record.sleep_min ?? 0) / 60.0
                                LineMark(
                                    x: .value("日付", shortDate(record.date)),
                                    y: .value("時間", hours)
                                )
                                .foregroundStyle(Color.indigo)
                                .interpolationMethod(.catmullRom)
                                .symbol(Circle())

                                AreaMark(
                                    x: .value("日付", shortDate(record.date)),
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
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.04))
                    .cornerRadius(12)
                    .padding(.horizontal, 12)
                }
            }
        }
    }

    // MARK: - 記録一覧

    private var recordListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("記録一覧")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)

            ForEach(filteredRecords.reversed()) { record in
                HStack(spacing: 10) {
                    // 日付
                    Text(shortDate(record.date))
                        .font(.caption.weight(.medium))
                        .frame(width: 40)

                    // NetStage バッジ
                    Text("\(record.net_stage >= 0 ? "+" : "")\(record.net_stage)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(stageColor(record.net_stage))
                        .cornerRadius(6)

                    // Danger
                    Text("D:\(record.danger)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(dangerTextColor(record.danger))

                    // RiskColor 丸
                    Circle()
                        .fill(riskSwiftUIColor(record.risk_color))
                        .frame(width: 12, height: 12)

                    Spacer()

                    // 歩数（あれば）
                    if let steps = record.steps {
                        Text("\(steps)歩")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // 服薬
                    if record.meds_am == true || record.meds_pm == true {
                        Image(systemName: "pills.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.04))
                .cornerRadius(8)
                .padding(.horizontal, 12)
            }
        }
    }

    // MARK: - ヘルパー

    private func shortDate(_ isoDate: String) -> String {
        // "2026-03-04" → "3/4"
        let parts = isoDate.split(separator: "-")
        guard parts.count == 3,
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return isoDate
        }
        return "\(month)/\(day)"
    }

    private func stageColor(_ stage: Int) -> Color {
        if stage >= 3 { return .red }
        if stage >= 1 { return .orange }
        if stage == 0 { return .gray }
        if stage >= -2 { return .cyan }
        return .blue
    }

    private func dangerTextColor(_ danger: Int) -> Color {
        switch danger {
        case 0...1: return .green
        case 2: return .yellow
        case 3: return .orange
        default: return .red
        }
    }

    private func dangerGradient(_ danger: Int) -> Color {
        switch danger {
        case 0: return .green
        case 1: return .mint
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
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
