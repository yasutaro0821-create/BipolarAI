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

