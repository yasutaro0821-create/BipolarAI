//
//  HistoryStore.swift
//  BipolarAI
//
//  Created on 2026-03-04
//  Local history storage service using UserDefaults
//

import Foundation

/// 履歴レコード
struct HistoryRecord: Codable, Identifiable {
    var id: String { date }
    var date: String
    var mood_score: Int
    var net_stage: Int
    var danger: Int
    var risk_color: String
    var subj_stage: Int
    var obj_stage: Int
    var steps: Int?
    var sleep_min: Int?
    var active_energy_kcal: Int?
    var alcohol_drinks: Int?
    var mindfulness_min: Int?
    var meds_am: Bool?
    var meds_pm: Bool?
    var coping3: [String]?
}

/// 履歴のローカル保存サービス
class HistoryStore: ObservableObject {
    static let shared = HistoryStore()

    @Published var records: [HistoryRecord] = []

    private let storageKey = "history_records"
    private let maxRecords = 90

    private init() {
        records = loadAll()
    }

    /// 送信結果を履歴に保存
    func save(log: DailyLog, result: CalculationResult) {
        let record = HistoryRecord(
            date: log.date,
            mood_score: log.mood_score,
            net_stage: result.net_stage,
            danger: result.danger,
            risk_color: result.risk_color,
            subj_stage: result.subj_stage,
            obj_stage: result.obj_stage,
            steps: log.steps,
            sleep_min: log.sleep_min,
            active_energy_kcal: log.active_energy_kcal,
            alcohol_drinks: log.alcohol_drinks,
            mindfulness_min: log.mindfulness_min,
            meds_am: log.meds_am_taken,
            meds_pm: log.meds_pm_taken,
            coping3: result.coping3.map { $0.text }
        )

        // 同じ日付の既存レコードを削除（上書き）
        records.removeAll { $0.date == record.date }
        records.append(record)

        // 日付順でソート（新しい順）
        records.sort { $0.date > $1.date }

        // 最大件数制限
        if records.count > maxRecords {
            records = Array(records.prefix(maxRecords))
        }

        saveToDefaults()
    }

    /// 全履歴を読み込み
    func loadAll() -> [HistoryRecord] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }
        do {
            return try JSONDecoder().decode([HistoryRecord].self, from: data)
        } catch {
            print("⚠️ History load error: \(error)")
            return []
        }
    }

    /// 直近N日分の履歴を取得
    func getLast(days: Int) -> [HistoryRecord] {
        let calendar = Calendar.current
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        let cutoffString = formatter.string(from: cutoffDate)

        return records.filter { $0.date >= cutoffString }
    }

    /// 全履歴を削除
    func deleteAll() {
        records = []
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    // MARK: - Private

    private func saveToDefaults() {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("⚠️ History save error: \(error)")
        }
    }
}
