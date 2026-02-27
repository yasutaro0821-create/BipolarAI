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
    
    var body: some View {
        Button(action: action) {
            Text("\(stage >= 0 ? "+" : "")\(stage)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 50, height: 50)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
    }
}

/// ステージ選択ビュー（-5..+5の11段階）
struct StageSelectorView: View {
    @Binding var selectedStage: Int?
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(-5...5, id: \.self) { stage in
                    StageButton(
                        stage: stage,
                        isSelected: selectedStage == stage
                    ) {
                        selectedStage = stage
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

