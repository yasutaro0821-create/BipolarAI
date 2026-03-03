//
//  ContentView.swift
//  BipolarAI
//
//  Created on 2025-12-22
//  Main content view with initial checkin flow + TabView
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
