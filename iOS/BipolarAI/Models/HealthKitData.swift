//
//  HealthKitData.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  HealthKit data model
//

import Foundation

/// HealthKitから取得するデータ
struct HealthKitData: Codable {
    // 歩数
    var steps: Int?
    
    // 睡眠
    var sleep_min: Int?  // 睡眠時間（分）
    var nap_min: Int?  // 仮眠時間（分）
    
    // エネルギー
    var active_energy_kcal: Int?  // 消費kcal
    var intake_energy_kcal: Int?  // 摂取kcal
    
    // マインドフルネス
    var mindfulness_min: Int?  // マインドフルネス実施時間（分）
    
    // 飲酒
    var alcohol_drinks: Int?  // 杯数
    
    // 体重（Phase2以降）
    var weight_kg: Double?
    
    /// 表示用フォーマット済みの値を返す
    func formattedSleep() -> String {
        guard let min = sleep_min else { return "未取得" }
        let hours = min / 60
        let mins = min % 60
        if hours > 0 {
            return "\(hours)時間\(mins)分"
        }
        return "\(mins)分"
    }

    func formattedNap() -> String {
        guard let min = nap_min, min > 0 else { return "なし" }
        return "\(min)分"
    }

    func formattedSteps() -> String {
        guard let s = steps else { return "未取得" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: s)) ?? "\(s)") + " 歩"
    }

    func formattedActiveEnergy() -> String {
        guard let e = active_energy_kcal else { return "未取得" }
        return "\(e) kcal"
    }

    func formattedIntakeEnergy() -> String {
        guard let e = intake_energy_kcal else { return "未取得" }
        return "\(e) kcal"
    }

    func formattedMindfulness() -> String {
        guard let m = mindfulness_min else { return "未取得" }
        return "\(m) 分"
    }

    func formattedAlcohol() -> String {
        guard let a = alcohol_drinks else { return "未取得" }
        return a == 0 ? "0 杯" : "\(a) 杯"
    }

    func formattedWeight() -> String {
        guard let w = weight_kg else { return "未設定" }
        return String(format: "%.1f kg", w)
    }

    /// DailyLogに統合
    func mergeInto(_ log: inout DailyLog) {
        if let steps = steps {
            log.steps = steps
        }
        if let sleep_min = sleep_min {
            log.sleep_min = sleep_min
        }
        if let nap_min = nap_min {
            log.nap_min = nap_min
        }
        if let active_energy_kcal = active_energy_kcal {
            log.active_energy_kcal = active_energy_kcal
        }
        if let intake_energy_kcal = intake_energy_kcal {
            log.intake_energy_kcal = intake_energy_kcal
        }
        if let mindfulness_min = mindfulness_min {
            log.mindfulness_min = mindfulness_min
        }
        if let alcohol_drinks = alcohol_drinks {
            log.alcohol_drinks = alcohol_drinks
        }
        if let weight_kg = weight_kg {
            log.weight_kg = weight_kg
        }
    }
}

/// 日別HealthKitデータ（トレンド表示用）
struct DailyHealthData: Identifiable {
    var id: String { dateString }
    let date: Date
    var dateString: String  // "3/1", "3/2" ...
    var steps: Int?
    var sleep_min: Int?
    var active_energy_kcal: Int?
    var mindfulness_min: Int?
    var alcohol_drinks: Int?
    var weight_kg: Double?
}

