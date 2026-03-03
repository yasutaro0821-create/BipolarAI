//
//  StageButton.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  Stage selection slider component (-5..+5)
//

import SwiftUI

/// ステージ選択スライダー（-5..+5）
struct StageSelectorView: View {
    @Binding var selectedStage: Int?
    let title: String

    @State private var sliderValue: Double = 0
    @State private var hasInteracted: Bool = false

    /// スライダー値に応じた色（青→灰→赤グラデーション）
    private var stageColor: Color {
        guard hasInteracted, let stage = selectedStage else { return .gray }
        let v = Double(stage)
        if v < 0 {
            // 鬱方向: 青系（-5=濃い青, -1=薄い青）
            let intensity = abs(v) / 5.0
            return Color(
                red: 0.2 * (1 - intensity) + 0.1 * intensity,
                green: 0.4 * (1 - intensity) + 0.3 * intensity,
                blue: 0.6 + 0.4 * intensity
            )
        } else if v > 0 {
            // 躁方向: 赤系（+1=薄い赤, +5=濃い赤）
            let intensity = v / 5.0
            return Color(
                red: 0.6 + 0.4 * intensity,
                green: 0.4 * (1 - intensity) + 0.2 * intensity,
                blue: 0.2 * (1 - intensity)
            )
        }
        return .gray
    }

    /// 値のテキスト表示
    private var valueText: String {
        guard hasInteracted, let stage = selectedStage else { return "未選択" }
        return "\(stage >= 0 ? "+" : "")\(stage)"
    }

    var body: some View {
        VStack(spacing: 8) {
            // タイトル行 + 値表示
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(valueText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(hasInteracted ? stageColor : .secondary)
                    .animation(.easeInOut(duration: 0.2), value: selectedStage)
            }

            // スライダー
            VStack(spacing: 4) {
                Slider(value: $sliderValue, in: -5...5, step: 1) { editing in
                    if editing && !hasInteracted {
                        hasInteracted = true
                    }
                    if !editing {
                        selectedStage = Int(sliderValue)
                    }
                }
                .tint(stageColor)
                .onChange(of: sliderValue) { newValue in
                    if hasInteracted {
                        selectedStage = Int(newValue)
                    }
                }

                // 目盛りラベル
                HStack {
                    Text("-5")
                    Spacer()
                    Text("-3")
                    Spacer()
                    Text("0")
                    Spacer()
                    Text("+3")
                    Spacer()
                    Text("+5")
                }
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [
                    hasInteracted ? stageColor.opacity(0.1) : Color.gray.opacity(0.04),
                    Color.gray.opacity(0.03)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .onAppear {
            if let stage = selectedStage {
                sliderValue = Double(stage)
                hasInteracted = true
            }
        }
    }
}
