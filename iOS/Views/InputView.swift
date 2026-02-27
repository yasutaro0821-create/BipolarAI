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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Mood選択
                    StageSelectorView(
                        selectedStage: $viewModel.moodStage,
                        title: "気分（Mood）"
                    )
                    
                    // 定型質問4本
                    StageSelectorView(
                        selectedStage: $viewModel.qMoodStage,
                        title: "定型質問①：気分"
                    )
                    
                    StageSelectorView(
                        selectedStage: $viewModel.qThinkingStage,
                        title: "定型質問②：考え"
                    )
                    
                    StageSelectorView(
                        selectedStage: $viewModel.qBodyStage,
                        title: "定型質問③：身体"
                    )
                    
                    StageSelectorView(
                        selectedStage: $viewModel.qBehaviorStage,
                        title: "定型質問④：行動"
                    )
                    
                    // 「今日は無理」ボタン
                    Button(action: {
                        viewModel.q4Status = .unable
                        // 定型質問をクリア
                        viewModel.qMoodStage = nil
                        viewModel.qThinkingStage = nil
                        viewModel.qBodyStage = nil
                        viewModel.qBehaviorStage = nil
                    }) {
                        Text("今日は無理")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // ジャーナルテキスト入力
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ジャーナル（任意）")
                            .font(.headline)
                        
                        TextEditor(text: $journalText)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // 送信ボタン
                    Button(action: {
                        submitData()
                    }) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("送信")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSubmit ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canSubmit || isSubmitting)
                    .padding(.horizontal)
                    
                    // エラーメッセージ
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("双極AI")
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
        }
    }
    
    /// 送信可能かどうか
    private var canSubmit: Bool {
        viewModel.moodStage != nil
    }
    
    /// データ送信
    private func submitData() {
        guard let moodStage = viewModel.moodStage else {
            errorMessage = "気分（Mood）を選択してください"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
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
        
        // 非同期で送信
        Task {
            do {
                let result = try await GASService.shared.submitDailyLog(log)
                await MainActor.run {
                    self.calculationResult = result
                    self.showResult = true
                    self.isSubmitting = false
                    
                    // LINE通知を送信（日次）
                    if let lineMessage = result.line_message, !lineMessage.isEmpty {
                        Task {
                            try? await LineNotifyService.shared.sendMessage(lineMessage)
                        }
                    }
                    
                    // Orange以上は即時で追加LINE
                    if result.line_send_immediate == true, let lineMessage = result.line_message {
                        Task {
                            try? await LineNotifyService.shared.sendMessage("⚠️ 危険度が高い状態です\n\n\(lineMessage)")
                        }
                    }
                    
                    // Rebootが必要な場合は表示
                    if result.reboot.reboot_needed {
                        self.rebootSheet = result.reboot
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
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

