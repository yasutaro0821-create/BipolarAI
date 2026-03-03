//
//  HealthMetricCard.swift
//  BipolarAI
//
//  Created on 2026-03-04
//  Health metric infographic card component
//

import SwiftUI
import Charts

/// メトリクスの取得状態
enum MetricStatus {
    case available   // データあり
    case missing     // HealthKit未取得
    case noData      // データなし（0）
}

/// HealthKitデータのインフォグラフィックカード
struct HealthMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let status: MetricStatus
    var trend: [Double]? = nil

    var body: some View {
        HStack(spacing: 8) {
            // 左: アイコン + テキスト
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(status == .available ? color : .gray)
                    Text(title)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.secondary)
                }

                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(status == .available ? .primary : .gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)

            // 右: ミニスパークライン（データがあれば）
            if let trend = trend, !trend.isEmpty {
                MiniSparkline(data: trend, color: color)
                    .frame(width: 50, height: 28)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [
                    status == .available ? color.opacity(0.12) : Color.gray.opacity(0.06),
                    status == .available ? color.opacity(0.04) : Color.gray.opacity(0.03)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
}

/// ミニスパークライン（7日分の推移）
struct MiniSparkline: View {
    let data: [Double]
    let color: Color

    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Day", index),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(color.opacity(0.7))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Day", index),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
        }
    }
}
