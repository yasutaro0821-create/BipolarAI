//
//  Constants.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  App constants and configuration
//

import Foundation

/// アプリ定数
struct Constants {
    /// GAS WebアプリURL
    /// TODO: 最新のデプロイURLに更新してください
    /// 確認方法: GASエディタ → デプロイ → 管理 → アクティブなデプロイ → URLをコピー
    static let GAS_ENDPOINT_URL = "https://script.google.com/macros/s/AKfycbwhfOswhC5kqt9C3kKU9CLcURie81ROL35pZD0UQgf0QvYKeWRNyEP7m4Y5RF8EQw1V/exec"
    
    /// アプリバージョン
    static let APP_VERSION = "1.0.0"
    
    /// ステージ範囲
    static let STAGE_MIN = -5
    static let STAGE_MAX = 5
    
    /// 定型質問のステータス
    enum Q4Status: String, CaseIterable {
        case answered = "answered"
        case unable = "unable"
        case missing = "missing"
        
        var displayName: String {
            switch self {
            case .answered: return "回答済み"
            case .unable: return "今日は無理"
            case .missing: return "未回答"
            }
        }
    }
}

