//
//  HealthKitService.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  HealthKit data reading service
//

import Foundation
import HealthKit

/// HealthKit読み取りエラー
enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case authorizationDenied
    case dataNotFound
    case readError(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKitが利用できません"
        case .authorizationDenied:
            return "HealthKitのアクセス許可が必要です"
        case .dataNotFound:
            return "データが見つかりません"
        case .readError(let error):
            return "データ読み取りエラー: \(error.localizedDescription)"
        }
    }
}

/// HealthKitデータ読み取りサービス
class HealthKitService {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()

    private init() {}

    /// HealthKitが利用可能か確認
    func isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    /// アクセス許可をリクエスト
    func requestAuthorization() async throws {
        guard isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        var readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        if let alcoholType = HKObjectType.quantityType(forIdentifier: .numberOfAlcoholicBeverages) {
            readTypes.insert(alcoholType)
        }

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    /// 今日のデータを取得
    func fetchTodayData() async throws -> HealthKitData {
        return try await fetchData(for: Date())
    }

    /// 指定日のデータを取得
    func fetchData(for date: Date) async throws -> HealthKitData {
        guard isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        var data = HealthKitData()

        if let steps = try? await fetchCumulativeQuantity(.stepCount, from: startOfDay, to: endOfDay, unit: HKUnit.count()) {
            data.steps = Int(steps)
        }

        if let energy = try? await fetchCumulativeQuantity(.activeEnergyBurned, from: startOfDay, to: endOfDay, unit: HKUnit.kilocalorie()) {
            data.active_energy_kcal = Int(energy)
        }

        if let intake = try? await fetchCumulativeQuantity(.dietaryEnergyConsumed, from: startOfDay, to: endOfDay, unit: HKUnit.kilocalorie()) {
            data.intake_energy_kcal = Int(intake)
        }

        if let sleepData = try? await fetchSleepData(from: startOfDay, to: endOfDay) {
            data.sleep_min = sleepData.sleepMinutes
            data.nap_min = sleepData.napMinutes
        }

        if let mindful = try? await fetchMindfulSession(from: startOfDay, to: endOfDay) {
            data.mindfulness_min = mindful
        }

        if let drinks = try? await fetchCumulativeQuantity(.numberOfAlcoholicBeverages, from: startOfDay, to: endOfDay, unit: HKUnit.count()) {
            data.alcohol_drinks = Int(drinks)
        }

        if let weight = try? await fetchLatestWeight() {
            data.weight_kg = weight
        }

        return data
    }

    /// 過去N日間の日別データを取得（トレンド表示用）
    func fetchDailyData(days: Int = 7) async throws -> [DailyHealthData] {
        guard isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: now))!
        let endDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d"

        // 日付配列を作成
        var dailyData: [DailyHealthData] = []
        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: i, to: startDate)!
            dailyData.append(DailyHealthData(
                date: date,
                dateString: dateFormatter.string(from: date)
            ))
        }

        // 歩数を日別取得
        if let stepsData = try? await fetchDailyQuantity(.stepCount, from: startDate, to: endDate, unit: HKUnit.count(), days: days) {
            for (index, value) in stepsData.enumerated() where index < dailyData.count {
                dailyData[index].steps = value != nil ? Int(value!) : nil
            }
        }

        // 消費カロリーを日別取得
        if let energyData = try? await fetchDailyQuantity(.activeEnergyBurned, from: startDate, to: endDate, unit: HKUnit.kilocalorie(), days: days) {
            for (index, value) in energyData.enumerated() where index < dailyData.count {
                dailyData[index].active_energy_kcal = value != nil ? Int(value!) : nil
            }
        }

        // 飲酒量を日別取得
        if let alcoholData = try? await fetchDailyQuantity(.numberOfAlcoholicBeverages, from: startDate, to: endDate, unit: HKUnit.count(), days: days) {
            for (index, value) in alcoholData.enumerated() where index < dailyData.count {
                dailyData[index].alcohol_drinks = value != nil ? Int(value!) : nil
            }
        }

        // 睡眠を日別取得
        for i in 0..<days {
            let dayStart = calendar.date(byAdding: .day, value: i, to: startDate)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            if let sleepData = try? await fetchSleepData(from: dayStart, to: dayEnd) {
                dailyData[i].sleep_min = sleepData.sleepMinutes > 0 ? sleepData.sleepMinutes : nil
            }
        }

        // マインドフルネスを日別取得
        for i in 0..<days {
            let dayStart = calendar.date(byAdding: .day, value: i, to: startDate)!
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            if let mindful = try? await fetchMindfulSession(from: dayStart, to: dayEnd) {
                dailyData[i].mindfulness_min = mindful > 0 ? mindful : nil
            }
        }

        return dailyData
    }

    /// 日別の累積数値データを取得（HKStatisticsCollectionQuery）
    private func fetchDailyQuantity(_ identifier: HKQuantityTypeIdentifier, from startDate: Date, to endDate: Date, unit: HKUnit, days: Int) async throws -> [Double?] {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw HealthKitError.dataNotFound
        }

        let calendar = Calendar.current
        let interval = DateComponents(day: 1)
        let anchorDate = calendar.startOfDay(for: startDate)

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.readError(error))
                    return
                }

                guard let results = results else {
                    continuation.resume(returning: Array(repeating: nil, count: days))
                    return
                }

                var values: [Double?] = []
                results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    if let sum = statistics.sumQuantity() {
                        values.append(sum.doubleValue(for: unit))
                    } else {
                        values.append(nil)
                    }
                }
                // enumerateStatistics may include endDate, trim to days count
                let trimmed = Array(values.prefix(days))
                continuation.resume(returning: trimmed)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Private Methods

    /// 累積型の数値データを取得（歩数、kcal、飲酒量など）
    private func fetchCumulativeQuantity(_ identifier: HKQuantityTypeIdentifier, from startDate: Date, to endDate: Date, unit: HKUnit) async throws -> Double {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw HealthKitError.dataNotFound
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.readError(error))
                    return
                }
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                continuation.resume(returning: sum.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    /// 睡眠データを取得
    private func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> (sleepMinutes: Int, napMinutes: Int) {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.dataNotFound
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.readError(error))
                    return
                }

                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: (0, 0))
                    return
                }

                var totalSleepSeconds: TimeInterval = 0
                var totalNapSeconds: TimeInterval = 0

                for sample in samples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)

                    switch value {
                    case .asleepCore, .asleepDeep, .asleepREM, .asleepUnspecified:
                        // 3時間未満は仮眠として扱う
                        if duration < 3 * 3600 {
                            totalNapSeconds += duration
                        } else {
                            totalSleepSeconds += duration
                        }
                    default:
                        break
                    }
                }

                continuation.resume(returning: (Int(totalSleepSeconds / 60), Int(totalNapSeconds / 60)))
            }
            healthStore.execute(query)
        }
    }

    /// マインドフルネスセッションの合計時間（分）を取得
    private func fetchMindfulSession(from startDate: Date, to endDate: Date) async throws -> Int {
        guard let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else {
            throw HealthKitError.dataNotFound
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: mindfulType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.readError(error))
                    return
                }

                guard let samples = samples else {
                    continuation.resume(returning: 0)
                    return
                }

                let totalSeconds = samples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: Int(totalSeconds / 60))
            }
            healthStore.execute(query)
        }
    }

    /// 最新の体重（kg）を取得
    private func fetchLatestWeight() async throws -> Double {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.dataNotFound
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.readError(error))
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(throwing: HealthKitError.dataNotFound)
                    return
                }

                let weightKg = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                continuation.resume(returning: weightKg)
            }
            healthStore.execute(query)
        }
    }
}
