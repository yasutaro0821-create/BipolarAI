//
//  ContentView.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  Main content view with initial checkin flow + TabView
//

import SwiftUI

struct ContentView: View {
    @AppStorage("lastCheckinDate") private var lastCheckinDate: String = ""
    @State private var checkinCompleted: Bool = false

    /// 昨日のチェックインが必要か（朝に記録するため、昨日分の記録済みかを確認）
    private var needsCheckin: Bool {
        if checkinCompleted { return false }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let today = formatter.string(from: Date())
        // 今日すでに何かを記録していればOK（昨日分を今朝記録したケース）
        return lastCheckinDate != today
    }

    var body: some View {
        ZStack {
            // メインのTabView
            TabView {
                DashboardView()
                    .tabItem {
                        Label("今日", systemImage: "heart.text.square")
                    }

                InputView()
                    .tabItem {
                        Label("記録", systemImage: "square.and.pencil")
                    }

                HistoryView()
                    .tabItem {
                        Label("履歴", systemImage: "clock.arrow.circlepath")
                    }

                CopingLibraryView()
                    .tabItem {
                        Label("対処法", systemImage: "list.bullet.clipboard")
                    }

                SettingsView()
                    .tabItem {
                        Label("設定", systemImage: "gearshape")
                    }
            }
        }
        .fullScreenCover(isPresented: .init(
            get: { needsCheckin },
            set: { _ in }
        )) {
            InputView(onSubmitSuccess: {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withFullDate]
                lastCheckinDate = formatter.string(from: Date())
                checkinCompleted = true
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
