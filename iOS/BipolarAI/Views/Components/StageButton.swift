//
//  StageButton.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  Stage selection button component (-5..+5)
//

import SwiftUI

/// ステージ選択ボタン（-5..+5）
struct StageButton: View {
    let stage: Int
    let isSelected: Bool
    let action: () -> Void

    private var stageColor: Color {
        if !isSelected { return Color.gray.opacity(0.2) }
        switch stage {
        case -5: return Color.red
        case -4: return Color.red.opacity(0.8)
        case -3: return Color.orange
        case -2: return Color.orange.opacity(0.7)
        case -1: return Color.yellow.opacity(0.8)
        case 0: return Color.gray.opacity(0.5)
        case 1: return Color.mint.opacity(0.7)
        case 2: return Color.green.opacity(0.6)
        case 3: return Color.green.opacity(0.7)
        case 4: return Color.blue.opacity(0.7)
        case 5: return Color.blue
        default: return Color.gray
        }
    }

    var body: some View {
        Button(action: action) {
            Text("\(stage >= 0 ? "+" : "")\(stage)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(stageColor)
                .cornerRadius(6)
        }
    }
}

/// ステージ選択ビュー（-5..+5の11段階、2行表示）
struct StageSelectorView: View {
    @Binding var selectedStage: Int?
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let stage = selectedStage {
                    Spacer()
                    Text("\(stage >= 0 ? "+" : "")\(stage)")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.blue)
                }
            }

            // 上段: -5 〜 0
            HStack(spacing: 4) {
                ForEach(-5...0, id: \.self) { stage in
                    StageButton(
                        stage: stage,
                        isSelected: selectedStage == stage
                    ) {
                        if selectedStage == stage {
                            selectedStage = nil
                        } else {
                            selectedStage = stage
                        }
                    }
                }
            }

            // 下段: +1 〜 +5
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { stage in
                    StageButton(
                        stage: stage,
                        isSelected: selectedStage == stage
                    ) {
                        if selectedStage == stage {
                            selectedStage = nil
                        } else {
                            selectedStage = stage
                        }
                    }
                }
                // 5個なので右側にスペーサー
                Color.clear.frame(maxWidth: .infinity, height: 36)
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.06))
        .cornerRadius(10)
    }
}

