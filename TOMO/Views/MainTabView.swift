//
// MainTabView.swift
//
// 이 파일은 앱의 메인 탭 기반 내비게이션 구조를 정의합니다.
// '오늘의 문구', '히스토리', '설정' 세 가지 주요 뷰를 탭 바로 연결하며,
// 사용자 설정(`UserSettings`)에 따라 탭 바의 외형(테마, 아이콘 색상)을 동적으로 조정합니다.
//
// 주요 기능:
// - 세 가지 핵심 뷰(`TodayQuoteView`, `HistoryCalendarView`, `ProfileSettingsView`)를 호스팅합니다.
// - `UserSettings`를 환경 객체로 주입하여 모든 하위 뷰에서 사용자 설정을 공유하고 반응하게 합니다.
// - 탭 바의 배경을 투명하게 설정하고, 선택된 탭 아이템의 색상을 다크/라이트 모드에 따라 다르게 지정합니다.
// - 사용자 테마 변경 시 탭 바의 외형을 즉시 업데이트하여 일관된 사용자 경험을 제공합니다.
//

import SwiftUI
import UIKit // UITabBarAppearance를 사용하기 위해 임포트

/// 앱의 메인 탭 기반 내비게이션을 정의하는 뷰.
/// 세 개의 주요 탭 뷰를 포함하며, 사용자 설정에 따라 탭 바의 외형을 동적으로 변경합니다.
struct MainTabView: View {
    /// 사용자 설정(테마, 폰트 등)을 관리하는 상태 객체.
    @StateObject var settings = UserSettings()
    /// `TabView`를 강제로 새로 고치기 위한 식별자. 테마 변경 시 탭 바 외형 업데이트에 사용됩니다.
    @State private var tabViewID = UUID()

    // MARK: - Body

    var body: some View {
        TabView {
            // 1. 오늘의 문구 탭
            TodayQuoteView()
                .environmentObject(settings) // UserSettings 환경 객체 주입
                .tabItem {
                    Label("오늘의 문구", systemImage: "sun.max") // 탭 아이템 레이블 및 시스템 이미지
                }

            // 2. 히스토리 탭 (문구 기록)
            HistoryCalendarView()
                .environmentObject(settings) // UserSettings 환경 객체 주입
                .tabItem {
                    Label("히스토리", systemImage: "calendar")
                }

            // 3. 설정 탭 (프로필 및 앱 설정)
            ProfileSettingsView()
                .environmentObject(settings) // UserSettings 환경 객체 주입
                .tabItem {
                    Label("설정", systemImage: "person.circle")
                }
        }
        .id(tabViewID) // TabView에 고유 ID를 부여하여, ID가 변경될 때 TabView가 강제로 재구성되도록 합니다.
        // MARK: - 탭바의 색상 설정 및 테마 적용
        .preferredColorScheme(settings.preferredColorScheme) // 사용자 설정에 따른 앱 전체의 색상 스킴 적용
        .onAppear {
            // 뷰가 나타날 때 초기 탭 바 외형 설정
            setTabBarAppearance(for: settings.preferredColorScheme)
            print("MainTabView ➡️ onAppear: Tab Bar appearance set based on initial color scheme.")
        }
        .onChange(of: settings.preferredColorScheme) { oldScheme, newScheme in
            // preferredColorScheme이 변경될 때 탭 바 외형 업데이트 및 TabView 강제 리프레시
            print("MainTabView 🔄 onChange: Color scheme changed from \(oldScheme) to \(newScheme). Updating Tab Bar appearance.")
            setTabBarAppearance(for: newScheme)
            tabViewID = UUID() // ID를 변경하여 TabView 전체를 강제로 리프레시합니다.
        }
        // `.toolbarColorScheme`은 iOS 16+에서 탭 바의 배경 색상 등을 설정할 수 있지만,
        // 아이템 색상까지 세밀하게 제어하기 어렵습니다. `UITabBarAppearance` 설정이 더 강력하고 유연합니다.
        // .toolbarColorScheme(settings.preferredColorScheme, for: .tabBar)
    }

    // MARK: - Helper Functions

    /// `UITabBarAppearance`를 사용하여 탭 바의 외형을 설정합니다.
    /// 배경, 선택되지 않은 아이템, 선택된 아이템의 색상을 동적으로 조절합니다.
    /// - Parameter scheme: 적용할 `ColorScheme` (다크 또는 라이트 모드).
    private func setTabBarAppearance(for scheme: ColorScheme) {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground() // 배경을 투명하게 설정
        appearance.backgroundColor = .clear // 배경색을 투명으로 설정

        // 선택되지 않은 아이템의 아이콘 및 텍스트 색상 (일반적으로 회색)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(.gray)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(.gray)]

        // 선택된 아이템의 아이콘 및 텍스트 색상 설정
        if scheme == .dark {
            // 다크 모드일 때: 선택된 아이콘/텍스트는 흰색
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(.white)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(.white)]
        } else {
            // 라이트 모드일 때: 선택된 아이콘/텍스트는 검정색
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(.black)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(.black)]
        }
        
        // Tab Bar에 설정된 외형 적용 (표준 외형 및 스크롤 엣지 외형)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
