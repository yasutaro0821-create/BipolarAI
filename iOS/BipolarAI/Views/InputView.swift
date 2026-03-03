//
//  InputView.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  Input view for Mood + 4 fixed questions
//

import SwiftUI

/// 入力画面（Mood + 定型質問4本）
struct InputView: View {
    @StateObject private var viewModel = InputViewModel()
    @State private var journalText: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showResult: Bool = false
    @State private var calculationResult: CalculationResult?
    @State private var errorMessage: String?
    @State private var rebootSheet: RebootStatus?
    @State private var healthStatus: String = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // HealthKit ステータス表示
                    if !healthStatus.isEmpty {
                        Text(healthStatus)
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal)
                    }

                    // Mood選択
                    StageSelectorView(
                        selectedStage: $viewModel.moodStage,
                        title: "気分（Mood）"
                    )

                    // 定型質問4本
                    StageSelectorView(
                        selectedStage: $viewModel.qMoodStage,
                        title: "①気分"
                    )

                    StageSelectorView(
                        selectedStage: $viewModel.qThinkingStage,
                        title: "②考え"
                    )

                    StageSelectorView(
                        selectedStage: $viewModel.qBodyStage,
                        title: "③身体"
                    )

                    StageSelectorView(
                        selectedStage: $viewModel.qBehaviorStage,
                        title: "④行動"
                    )

                    // 「今日は無理」ボタン
                    Button(action: {
                        viewModel.q4Status = .unable
                        viewModel.qMoodStage = nil
                        viewModel.qThinkingStage = nil
                        viewModel.qBodyStage = nil
                        viewModel.qBehaviorStage = nil
                    }) {
                        Text("今日は無理")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                    }

                    // ジャーナルテキスト入力
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ジャーナル（任意）")
                            .font(.caption.weight(.semibold))

                        TextEditor(text: $journalText)
                            .frame(height: 80)
                            .padding(6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 4)

                    // 送信ボタン
                    Button(action: {
                        submitData()
                    }) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("送信中...")
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("送信")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(canSubmit ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!canSubmit || isSubmitting)

                    // エラーメッセージ
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .navigationTitle("双極AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showResult) {
                if let result = calculationResult {
                    ResultView(result: result)
                }
            }
            .sheet(item: $rebootSheet) { status in
                RebootView(rebootStatus: status)
            }
            .task {
                await fetchHealthStatus()
            }
        }
    }

    /// 送信可能かどうか
    private var canSubmit: Bool {
        viewModel.moodStage != nil
    }

    /// HealthKitステータス確認
    private func fetchHealthStatus() async {
        do {
            let data = try await HealthKitService.shared.fetchTodayData()
            var parts: [String] = []
            if let steps = data.steps, steps > 0 { parts.append("歩数:\(steps)") }
            if let sleep = data.sleep_min, sleep > 0 { parts.append("睡眠:\(sleep)分") }
            if let energy = data.active_energy_kcal, energy > 0 { parts.append("消費:\(energy)kcal") }
            if parts.isEmpty {
                healthStatus = "🔗 HealthKit接続済み（データ取得待ち）"
            } else {
                healthStatus = "🔗 " + parts.joined(separator: " / ")
            }
        } catch {
            healthStatus = "⚠️ HealthKit未接続"
        }
    }

    /// データ送信
    private func submitData() {
        guard let moodStage = viewModel.moodStage else {
            errorMessage = "気分（Mood）を選択してください"
            return
        }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                // HealthKitデータ取得
                var healthData: HealthKitData?
                do {
                    healthData = try await HealthKitService.shared.fetchTodayData()
                    print("✅ HealthKit data fetched: steps=\(healthData?.steps ?? 0)")
                } catch {
                    print("⚠️ HealthKit fetch failed: \(error.localizedDescription)")
                }

                // DailyLog作成
                var log = DailyLog.today(
                    mood_score: moodStage,
                    journal_text: journalText.isEmpty ? nil : journalText,
                    q_mood_stage: viewModel.qMoodStage,
                    q_thinking_stage: viewModel.qThinkingStage,
                    q_body_stage: viewModel.qBodyStage,
                    q_behavior_stage: viewModel.qBehaviorStage,
                    q4_status: viewModel.q4Status.rawValue
                )

                // HealthKitデータをDailyLogに統合
                healthData?.mergeInto(&log)

                // GASに送信
                let result = try await GASService.shared.submitDailyLog(log)

                await MainActor.run {
                    self.calculationResult = result
                    self.showResult = true
                    self.isSubmitting = false

                    // Rebootが必要な場合は表示
                    if result.reboot.reboot_needed {
                        self.rebootSheet = result.reboot
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "送信エラー: \(error.localizedDescription)"
                    self.isSubmitting = false
                }
            }
        }
    }
}

/// 入力画面のViewModel
class InputViewModel: ObservableObject {
    @Published var moodStage: Int?
    @Published var qMoodStage: Int?
    @Published var qThinkingStage: Int?
    @Published var qBodyStage: Int?
    @Published var qBehaviorStage: Int?
    @Published var q4Status: Constants.Q4Status = .answered
}
