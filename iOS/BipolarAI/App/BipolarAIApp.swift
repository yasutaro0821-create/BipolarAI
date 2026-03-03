//
//  BipolarAIApp.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  App entry point
//

import SwiftUI

@main
struct BipolarAIApp: App {
    @State private var healthKitAuthorized = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // アプリ起動時にHealthKit権限をリクエスト
                    do {
                        try await HealthKitService.shared.requestAuthorization()
                        healthKitAuthorized = true
                        print("✅ HealthKit authorization granted")
                    } catch {
                        print("⚠️ HealthKit authorization failed: \(error.localizedDescription)")
                    }
                }
        }
    }
}
