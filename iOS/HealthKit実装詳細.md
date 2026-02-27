# HealthKit実装詳細

## 実装が必要なメソッド

`Services/HealthKitService.swift` の以下のメソッドを実装する必要があります：

### 1. fetchStepCount（歩数）

```swift
private func fetchStepCount(from startDate: Date, to endDate: Date) async throws -> Double {
    guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
        throw HealthKitError.dataNotFound
    }
    
    return try await withCheckedThrowingContinuation { continuation in
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { query, result, error in
            if let error = error {
                continuation.resume(throwing: HealthKitError.readError(error))
                return
            }
            
            guard let result = result,
                  let sum = result.sumQuantity() else {
                continuation.resume(returning: 0)
                return
            }
            
            continuation.resume(returning: sum.doubleValue(for: HKUnit.count()))
        }
        
        healthStore.execute(query)
    }
}
```

### 2. fetchActiveEnergy（消費kcal）

同様のパターンで実装：

```swift
private func fetchActiveEnergy(from startDate: Date, to endDate: Date) async throws -> Double {
    guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
        throw HealthKitError.dataNotFound
    }
    
    return try await withCheckedThrowingContinuation { continuation in
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: energyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { query, result, error in
            if let error = error {
                continuation.resume(throwing: HealthKitError.readError(error))
                return
            }
            
            guard let result = result,
                  let sum = result.sumQuantity() else {
                continuation.resume(returning: 0)
                return
            }
            
            continuation.resume(returning: sum.doubleValue(for: HKUnit.kilocalorie()))
        }
        
        healthStore.execute(query)
    }
}
```

### 3. fetchDietaryEnergy（摂取kcal）

同様のパターンで実装（`dietaryEnergyConsumed` を使用）

### 4. fetchSleepData（睡眠データ）

睡眠データは `HKCategoryType.sleepAnalysis` を使用：

```swift
private func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> (sleepMinutes: Int, napMinutes: Int) {
    guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
        throw HealthKitError.dataNotFound
    }
    
    return try await withCheckedThrowingContinuation { continuation in
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { query, samples, error in
            if let error = error {
                continuation.resume(throwing: HealthKitError.readError(error))
                return
            }
            
            guard let samples = samples as? [HKCategorySample] else {
                continuation.resume(returning: (0, 0))
                return
            }
            
            var sleepMinutes = 0
            var napMinutes = 0
            
            for sample in samples {
                let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60
                
                switch sample.value {
                case HKCategoryValueSleepAnalysis.asleep.rawValue,
                     HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                     HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                     HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    sleepMinutes += Int(duration)
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    // 短いawakeは仮眠として扱う（例：30分未満）
                    if duration < 30 {
                        napMinutes += Int(duration)
                    }
                default:
                    break
                }
            }
            
            continuation.resume(returning: (sleepMinutes, napMinutes))
        }
        
        healthStore.execute(query)
    }
}
```

### 5. fetchMindfulSession（マインドフルネス）

`HKCategoryType.mindfulSession` を使用して実装

### 6. fetchAlcoholicBeverages（飲酒）

`HKQuantityType.numberOfAlcoholicBeverages` を使用して実装（利用可能な場合）

### 7. fetchLatestWeight（体重）

`HKQuantityType.bodyMass` を使用して、最新の記録を取得

## 実装のポイント

1. **非同期処理**: `async/await` と `withCheckedThrowingContinuation` を使用
2. **エラーハンドリング**: 各メソッドで適切にエラーを処理
3. **単位変換**: HealthKitの単位を適切に変換（例：kcal、分）
4. **データがない場合**: データがない場合は `0` または `nil` を返す

## テスト方法

1. 実機でテスト（シミュレーターでは動作しません）
2. 設定アプリでHealthKitのアクセス許可を確認
3. 各データタイプが正しく取得できるか確認

