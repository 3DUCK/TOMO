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
        // MARK: - 탭바의 색상 설정 (기본 및 선택 색상)
        .preferredColorScheme(settings.preferredColorScheme)
        .onAppear {
            // UITabBarAppearance를 사용하여 탭바의 외형을 커스터마이징합니다.
            let appearance = UITabBarAppearance()

            // MARK: 배경을 완전히 투명하게 설정하는 새로운 방법
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear // 배경색을 완전히 투명하게 설정
            
            // 다크 모드와 라이트 모드에 따라 색상 설정
            if settings.preferredColorScheme == .dark {
                // 다크 모드일 때
                //appearance.backgroundColor = UIColor(.black.opacity(0.8)) // 탭바 배경색
                appearance.stackedLayoutAppearance.normal.iconColor = UIColor(.gray) // 선택되지 않은 아이콘 색상 (기본: 회색)
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(.gray)] // 선택되지 않은 텍스트 색상 (기본: 회색)
                
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor(.white) // 선택된 아이콘 색상 (선택: 흰색)
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(.white)] // 선택된 텍스트 색상 (선택: 흰색)

            } else {
                // 라이트 모드일 때
                //appearance.backgroundColor = UIColor(.white.opacity(0.8)) // 탭바 배경색
                appearance.stackedLayoutAppearance.normal.iconColor = UIColor(.gray) // 선택되지 않은 아이콘 색상 (기본: 회색)
                appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(.gray)] // 선택되지 않은 텍스트 색상 (기본: 회색)
                
                appearance.stackedLayoutAppearance.selected.iconColor = UIColor(.black) // 선택된 아이콘 색상 (선택: 검은색)
                appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(.black)] // 선택된 텍스트 색상 (선택: 검은색)
            }

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance // 스크롤 시에도 동일한 외형 유지
        }
        // .toolbarColorScheme을 사용하면 iOS 16 이상에서 탭바 배경 색상 등을 설정할 수 있지만,
        // 아이템 색상까지 세밀하게 제어하기 어렵습니다. 위 UITabBarAppearance 설정이 더 강력합니다.
        // .toolbarColorScheme(settings.preferredColorScheme, for: .tabBar)
    }
}
