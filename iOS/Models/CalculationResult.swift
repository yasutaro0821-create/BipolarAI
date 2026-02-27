//
//  CalculationResult.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  Calculation result data model from GAS endpoint
//

import Foundation

/// GASエンドポイントからの計算結果
struct CalculationResult: Codable {
    var ok: Bool
    var log_id: Int?
    var output_id: Int?
    
    // 主要指標
    var net_stage: Int  // -5..+5
    var danger: Int  // 0..5
    var risk_color: String  // Green/Lime/Yellow/Orange/Red/DarkRed
    var subj_stage: Int  // -5..+5
    var obj_stage: Int  // -5..+5
    var gap: Int  // abs(subj_stage - obj_stage)
    
    // TopDrivers（上位3つ）
    var top_drivers: [TopDriver]
    
    // Coping3（3つ）
    var coping3: [Coping]
    
    // Reboot状態
    var reboot: RebootStatus
    
    // LINE通知
    var line_message: String?
    var line_send_immediate: Bool?
    
    // バージョン
    var version: String?
    
    // デバッグ情報（開発中のみ）
    var _debug_coping: DebugCoping?
    
    // エラー
    var error: String?
}

/// TopDriver（寄与要因）
struct TopDriver: Codable {
    var domain: String
    var contribution: Int
    var description: String
    var type: String?  // "danger" / "netstage"
}

/// Coping（コーピング提案）
struct Coping: Codable {
    var domain: String
    var text: String
}

/// Reboot状態
struct RebootStatus: Codable, Identifiable {
    var id = UUID()
    var reboot_needed: Bool
    var reboot_level: String?  // "L1" / "L2" / "L3"
    var reboot_step: String?  // "Reset" / "Reframe" / "Reconnect"
    var checkin_streak: Int?
    var journal_streak: Int?
    var days_since_last_checkin: Int?
    var days_since_last_journal: Int?
}

/// デバッグ情報（開発中のみ）
struct DebugCoping: Codable {
    var sheetFound: Bool?
    var dataRows: Int?
    var itemCol: Int?
    var stageCols: [Int]?
    var errors: [String]?
    var foundCount: Int?
    var triedDomains: [String]?
}

/// RiskColorの列挙型（表示用）
enum RiskColor: String, CaseIterable {
    case green = "Green"
    case lime = "Lime"
    case yellow = "Yellow"
    case orange = "Orange"
    case red = "Red"
    case darkRed = "DarkRed"
    
    /// 色の説明
    var description: String {
        switch self {
        case .green: return "安全"
        case .lime: return "注意"
        case .yellow: return "要観察"
        case .orange: return "危険"
        case .red: return "高リスク"
        case .darkRed: return "緊急"
        }
    }
    
    /// 色コード（SwiftUI用）
    var colorName: String {
        switch self {
        case .green: return "green"
        case .lime: return "green"
        case .yellow: return "yellow"
        case .orange: return "orange"
        case .red: return "red"
        case .darkRed: return "red"
        }
    }
}

