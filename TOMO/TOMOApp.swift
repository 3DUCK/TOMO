//
// TOMOApp.swift
//
// 이 파일은 TOMO 애플리케이션의 진입점(Entry Point)을 정의합니다.
// 앱의 생명 주기를 관리하고, 초기 설정(Firebase 초기화 등)을 수행하며,
// 앱의 루트 뷰(`MainTabView`)를 설정하고 `UserSettings`를 전역적으로 사용할 수 있도록 환경에 주입합니다.
//
// 주요 기능:
// - Firebase SDK를 초기화하여 앱에서 Firebase 서비스를 사용할 수 있도록 합니다.
// - 사용자 설정(`UserSettings`)을 앱 전역에서 접근 가능한 환경 객체로 제공합니다.
// - 앱의 최상위 UI인 `MainTabView`를 로드하여 사용자가 앱과 상호작용할 수 있도록 합니다.
//

import SwiftUI
import FirebaseCore // Firebase SDK를 사용하기 위해 임포트

/// TOMO 애플리케이션의 메인 엔트리 포인트 구조체.
/// `@main` 어트리뷰트를 통해 앱의 시작점을 선언합니다.
@main
struct TOMOApp: App {
    /// 사용자 설정(테마, 폰트, 목표 등)을 앱 전역에서 공유하고 관리하는 상태 객체.
    @StateObject var settings = UserSettings()
    
    /// `TOMOApp`의 초기화 메서드.
    /// 앱이 시작될 때 필요한 초기 설정을 수행합니다.
    init() {
        // Firebase Core SDK를 초기화합니다.
        // 이 코드가 실행되어야 Firebase의 다른 서비스(Firestore, Authentication 등)를 사용할 수 있습니다.
        FirebaseApp.configure()
        print("FirebaseApp configured successfully.") // Firebase 초기화 성공 로그
    }
    
    /// 앱의 UI 콘텐츠와 생명 주기를 정의하는 메서드.
    var body: some Scene {
        WindowGroup {
            // 앱의 메인 탭 뷰를 표시합니다.
            MainTabView()
                // `UserSettings` 객체를 환경(Environment)에 주입하여,
                // `MainTabView` 및 그 하위의 모든 뷰에서 `settings` 객체를 `@EnvironmentObject`로 접근할 수 있도록 합니다.
                .environmentObject(settings)
        }
    }
}

// MARK: - Preview

/// SwiftUI 캔버스에서 `MainTabView`를 미리 보기 위한 코드.
/// 실제 앱 실행 환경과 유사하게 `UserSettings`가 주입된 `MainTabView`를 보여줍니다.
#Preview {
    MainTabView()
        // 미리 보기에서도 `UserSettings`를 주입하여 뷰가 올바르게 렌더링되도록 합니다.
        // 실제 앱의 `@StateObject`와 달리 미리 보기에서는 새로운 인스턴스를 생성하여 주입합니다.
        .environmentObject(UserSettings())
}
