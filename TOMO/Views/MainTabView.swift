// MARK: - MainTabView.swift (UserSettings 적용)
import SwiftUI

struct MainTabView: View {
    @StateObject var settings = UserSettings()

    var body: some View {
        TabView {
            TodayQuoteView()
                .environmentObject(settings)
                .tabItem {
                    Label("오늘의 문구", systemImage: "sun.max")
                }

            HistoryCalendarView()
                .environmentObject(settings)
                .tabItem {
                    Label("히스토리", systemImage: "calendar")
                }

            ProfileSettingsView()
                .environmentObject(settings)
                .tabItem {
                    Label("설정", systemImage: "person.circle")
                }
        }
        .preferredColorScheme(settings.preferredColorScheme)
        .toolbarColorScheme(settings.preferredColorScheme, for: .tabBar)
    }
}
