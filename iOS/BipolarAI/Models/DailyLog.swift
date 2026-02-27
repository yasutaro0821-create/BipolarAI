//
//  DailyLog.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  Daily log data model for sending to GAS endpoint
//

import Foundation

/// 日次ログデータ（GASエンドポイントに送信するデータ）
struct DailyLog: Codable {
    // 基本情報
    var date: String  // ISO形式: "2025-12-21"
    
    // 必須入力
    var mood_score: Int  // -5..+5
    var journal_text: String?  // ジャーナルテキスト（任意）
    
    // 定型質問4本（-5..+5、任意）
    var q_mood_stage: Int?  // 定型：気分
    var q_thinking_stage: Int?  // 定型：考え
    var q_body_stage: Int?  // 定型：身体
    var q_behavior_stage: Int?  // 定型：行動
    var q4_status: String?  // "answered" / "unable" / "missing"
    var q4_reason: String?  // 任意メモ
    
    // 服薬
    var meds_am_taken: Bool?
    var meds_pm_taken: Bool?
    
    // HealthKitデータ（Phase1では最小限）
    var steps: Int?
    var intake_energy_kcal: Int?
    var sleep_min: Int?
    var nap_min: Int?
    var active_energy_kcal: Int?
    var mindfulness_min: Int?
    var alcohol_drinks: Int?
    
    // その他（Phase2以降）
    var calendar_occupancy_pct: Int?
    var calendar_event_count: Int?
    var time_at_home_min: Int?
    var time_at_work_min: Int?
    var time_at_mtinn_min: Int?
    var time_at_dake_min: Int?
    var weight_kg: Double?
    
    /// 最小限のデータで初期化（フェーズA用）
    init(
        date: String,
        mood_score: Int,
        journal_text: String? = nil,
        q_mood_stage: Int? = nil,
        q_thinking_stage: Int? = nil,
        q_body_stage: Int? = nil,
        q_behavior_stage: Int? = nil,
        q4_status: String? = "answered",
        q4_reason: String? = nil,
        meds_am_taken: Bool? = nil,
        meds_pm_taken: Bool? = nil
    ) {
        self.date = date
        self.mood_score = mood_score
        self.journal_text = journal_text
        self.q_mood_stage = q_mood_stage
        self.q_thinking_stage = q_thinking_stage
        self.q_body_stage = q_body_stage
        self.q_behavior_stage = q_behavior_stage
        self.q4_status = q4_status
        self.q4_reason = q4_reason
        self.meds_am_taken = meds_am_taken
        self.meds_pm_taken = meds_pm_taken
    }
    
    /// 現在の日付で初期化
    static func today(
        mood_score: Int,
        journal_text: String? = nil,
        q_mood_stage: Int? = nil,
        q_thinking_stage: Int? = nil,
        q_body_stage: Int? = nil,
        q_behavior_stage: Int? = nil,
        q4_status: String? = "answered"
    ) -> DailyLog {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let today = formatter.string(from: Date())
        
        return DailyLog(
            date: today,
            mood_score: mood_score,
            journal_text: journal_text,
            q_mood_stage: q_mood_stage,
            q_thinking_stage: q_thinking_stage,
            q_body_stage: q_body_stage,
            q_behavior_stage: q_behavior_stage,
            q4_status: q4_status
        )
    }
}

