//
//  InputView.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  Input view for Mood + 4 fixed questions + medication
//

import SwiftUI

/// 入力画面（Mood + 定型質問4本 + 服薬）
struct InputView: View {
    @StateObject private var viewModel = InputViewModel()
    @State private var journalText: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showResult: Bool = false
    @State private var calculationResult: CalculationResult?
    @State private var errorMessage: String?
    @State private var rebootSheet: RebootStatus?
    @State private var showSubmitSuccess: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // Mood選択
                    StageSelectorView(
                        selectedStage: $viewModel.moodStage,
                        title: "気分（総合）"
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

                    // 服薬記録
                    VStack(alignment: .leading, spacing: 8) {
                        Text("服薬")
                            .font(.subheadline.weight(.semibold))

                        HStack(spacing: 16) {
                            Toggle(isOn: $viewModel.medsAmTaken) {
                                HStack(spacing: 4) {
                                    Image(systemName: "sun.max.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    Text("AM（朝）")
                                        .font(.subheadline)
                                }
                            }
                            .toggleStyle(.switch)

                            Toggle(isOn: $viewModel.medsPmTaken) {
                                HStack(spacing: 4) {
                                    Image(systemName: "moon.fill")
                                        .font(.caption)
                                        .foregroundColor(.indigo)
                                    Text("PM（夕）")
                                        .font(.subheadline)
                                }
                            }
                            .toggleStyle(.switch)
                        }
                    }
                    .padding(10)
                    .background(Color.gray.opacity(0.06))
                    .cornerRadius(10)

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

                    // 送信成功メッセージ
                    if showSubmitSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("送信しました！")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.green)
                        }
                        .transition(.opacity)
                    }

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
            .navigationTitle("記録")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showResult) {
                if let result = calculationResult {
                    ResultView(result: result)
                }
            }
            .sheet(item: $rebootSheet) { status in
                RebootView(rebootStatus: status)
            }
        }
    }

    /// 送信可能かどうか
    private var canSubmit: Bool {
        viewModel.moodStage != nil
    }

    /// データ送信
    private func submitData() {
        guard let moodStage = viewModel.moodStage else {
            errorMessage = "気分（総合）を選択してください"
            return
        }

        isSubmitting = true
        errorMessage = nil
        showSubmitSuccess = false

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
                    q4_status: viewModel.q4Status.rawValue,
                    meds_am_taken: viewModel.medsAmTaken ? true : nil,
                    meds_pm_taken: viewModel.medsPmTaken ? true : nil
                )

                // HealthKitデータをDailyLogに統合
                healthData?.mergeInto(&log)

                // GASに送信
                let result = try await GASService.shared.submitDailyLog(log)

                await MainActor.run {
                    self.calculationResult = result
                    self.isSubmitting = false

                    // 履歴に保存
                    HistoryStore.shared.save(log: log, result: result)

                    // 前回結果をUserDefaultsに保存
                    if let data = try? JSONEncoder().encode(result) {
                        UserDefaults.standard.set(data, forKey: "lastCalculationResult")
                    }

                    // 服薬状態をUserDefaultsに保存（ダッシュボード表示用）
                    let todayKey = log.date
                    if viewModel.medsAmTaken {
                        UserDefaults.standard.set(true, forKey: "medsAmTaken_\(todayKey)")
                    }
                    if viewModel.medsPmTaken {
                        UserDefaults.standard.set(true, forKey: "medsPmTaken_\(todayKey)")
                    }

                    // フォームリセット
                    viewModel.reset()
                    journalText = ""

                    // 送信成功表示
                    showSubmitSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { showSubmitSuccess = false }
                    }

                    // 結果表示
                    self.showResult = true

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
    @Published var medsAmTaken: Bool = false
    @Published var medsPmTaken: Bool = false

    func reset() {
        moodStage = nil
        qMoodStage = nil
        qThinkingStage = nil
        qBodyStage = nil
        qBehaviorStage = nil
        q4Status = .answered
        medsAmTaken = false
        medsPmTaken = false
    }
}
