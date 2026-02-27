//
//  ResultView.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  Result display view
//

import SwiftUI

/// 結果表示画面
struct ResultView: View {
    let result: CalculationResult
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 主要指標
                    VStack(spacing: 12) {
                        Text("計算結果")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("NetStage")
                                    .font(.caption)
                                Text("\(result.net_stage >= 0 ? "+" : "")\(result.net_stage)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(stageColor(result.net_stage))
                            }
                            
                            VStack {
                                Text("Danger")
                                    .font(.caption)
                                Text("\(result.danger)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(dangerColor(result.danger))
                            }
                            
                            VStack {
                                Text("RiskColor")
                                    .font(.caption)
                                Text(result.risk_color)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(riskColor(result.risk_color))
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // SubjStage / ObjStage
                    HStack(spacing: 20) {
                        VStack {
                            Text("主観")
                                .font(.caption)
                            Text("\(result.subj_stage >= 0 ? "+" : "")\(result.subj_stage)")
                                .font(.headline)
                        }
                        
                        VStack {
                            Text("客観")
                                .font(.caption)
                            Text("\(result.obj_stage >= 0 ? "+" : "")\(result.obj_stage)")
                                .font(.headline)
                        }
                        
                        if result.gap >= 2 {
                            VStack {
                                Text("ズレ")
                                    .font(.caption)
                                Text("\(result.gap)")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // TopDrivers
                    if !result.top_drivers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("主な要因")
                                .font(.headline)
                            
                            ForEach(Array(result.top_drivers.enumerated()), id: \.offset) { index, driver in
                                if !driver.description.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(index + 1). \(driver.description)")
                                            .font(.subheadline)
                                    }
                                    .padding(8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    // Coping3
                    if !result.coping3.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("今日のアクション")
                                .font(.headline)
                            
                            ForEach(Array(result.coping3.enumerated()), id: \.offset) { index, coping in
                                if !coping.text.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(index + 1). \(coping.text)")
                                            .font(.subheadline)
                                    }
                                    .padding(8)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    // Reboot状態
                    if result.reboot.reboot_needed {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rebootが必要です")
                                .font(.headline)
                                .foregroundColor(.orange)
                            
                            if let level = result.reboot.reboot_level {
                                Text("レベル: \(level)")
                                    .font(.subheadline)
                            }
                            
                            if let step = result.reboot.reboot_step {
                                Text("ステップ: \(step)")
                                    .font(.subheadline)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    /// ステージの色
    private func stageColor(_ stage: Int) -> Color {
        if stage > 0 {
            return .red
        } else if stage < 0 {
            return .blue
        } else {
            return .gray
        }
    }
    
    /// Dangerの色
    private func dangerColor(_ danger: Int) -> Color {
        switch danger {
        case 0...1: return .green
        case 2: return .yellow
        case 3: return .orange
        default: return .red
        }
    }
    
    /// RiskColorの色
    private func riskColor(_ riskColor: String) -> Color {
        switch riskColor {
        case "Green": return .green
        case "Lime": return .green
        case "Yellow": return .yellow
        case "Orange": return .orange
        case "Red": return .red
        case "DarkRed": return .red
        default: return .gray
        }
    }
}

