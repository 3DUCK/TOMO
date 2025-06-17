// MARK: - MainTabView.swift (UserSettings 적용)
import SwiftUI

struct MainTabView: View {
    @StateObject var settings = UserSettings()
    @State private var tabViewID = UUID() // TabView를 강제로 리프레시할 식별자

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
        .id(tabViewID) // TabView에 식별자 부여
        // MARK: - 탭바의 색상 설정 (기본 및 선택 색상)
        .preferredColorScheme(settings.preferredColorScheme)
        .onAppear {
            setTabBarAppearance(for: settings.preferredColorScheme)
        }
        .onChange(of: settings.preferredColorScheme) { newScheme, _ in
            setTabBarAppearance(for: newScheme)
            tabViewID = UUID() // TabView를 강제로 리프레시
        }
        // .toolbarColorScheme을 사용하면 iOS 16 이상에서 탭바 배경 색상 등을 설정할 수 있지만,
        // 아이템 색상까지 세밀하게 제어하기 어렵습니다. 위 UITabBarAppearance 설정이 더 강력합니다.
        // .toolbarColorScheme(settings.preferredColorScheme, for: .tabBar)
    }

    private func setTabBarAppearance(for scheme: ColorScheme) {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(.gray)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(.gray)]
//        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(.black)
//        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(.black)]
        if settings.preferredColorScheme == .dark {
            // 다크 모드: 선택된 아이콘/텍스트는 흰색
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(.white)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(.white)]
        } else {
            // 라이트 모드: 선택된 아이콘/텍스트는 검정색
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(.black)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(.black)]
        }
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
