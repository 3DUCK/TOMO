//
// UserSettings.swift
//
// 이 파일은 앱의 사용자 설정(환경설정)을 관리하는 `ObservableObject` 클래스입니다.
// 사용자의 닉네임, 목표, 폰트, 사운드, 테마, 배경 이미지 등 다양한 설정 값을
// `UserDefaults`의 앱 그룹 컨테이너를 통해 앱과 위젯 간에 공유하고 저장합니다.
//
// @Published 프로퍼티를 사용하여 SwiftUI 뷰에서 설정 변경을 실시간으로 감지하고 UI를 업데이트하며,
// 설정 변경 시 위젯의 타임라인을 새로고침하여 위젯에도 최신 정보가 반영되도록 합니다.
// 또한, 선택된 폰트 이름에 따라 실제 `Font` 객체를 반환하는 헬퍼 메서드를 제공합니다.
//

import Foundation
import SwiftUI
import WidgetKit // WidgetCenter를 사용하기 위해 필요

/// 사용자의 프로필 정보를 담는 구조체.
/// Codable을 준수하여 인코딩 및 디코딩이 가능합니다.
struct UserProfile: Codable {
    var nickname: String // 사용자 닉네임
    var goal: String     // 사용자 목표
    var font: String     // 선택된 폰트 이름
    var sound: String    // 선택된 사운드 설정
    var theme: String    // 선택된 테마 (라이트/다크)
}

/// 앱의 사용자 설정을 관리하는 ObservableObject 클래스.
/// SwiftUI 뷰에서 관찰하여 설정 변경 시 UI를 업데이트합니다.
class UserSettings: ObservableObject {
    
    // AppConstants에 정의된 앱 그룹 ID를 사용하여 UserDefaults 인스턴스를 초기화합니다.
    private let defaults = UserDefaults(suiteName: AppConstants.appGroupID)!

    // MARK: - Published Properties

    /// 사용자의 닉네임. 변경 시 UserDefaults에 저장하고 위젯을 업데이트합니다.
    @Published var nickname: String {
        didSet {
            defaults.set(nickname, forKey: "nickname")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// 사용자의 목표. 변경 시 UserDefaults에 저장하고 위젯을 업데이트합니다.
    @Published var goal: String {
        didSet {
            defaults.set(goal, forKey: "goal")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// 사용자가 선택한 폰트 이름. 변경 시 UserDefaults에 저장하고 위젯을 업데이트합니다.
    @Published var font: String {
        didSet {
            defaults.set(font, forKey: "font")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// 사용자가 선택한 사운드 설정. 변경 시 UserDefaults에 저장하고 위젯을 업데이트합니다.
    @Published var sound: String {
        didSet {
            defaults.set(sound, forKey: "sound")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// 사용자가 선택한 테마 (라이트/다크). 변경 시 UserDefaults에 저장하고 위젯을 업데이트합니다.
    @Published var theme: String {
        didSet {
            defaults.set(theme, forKey: "theme")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    /// 사용자가 설정한 배경 이미지 데이터 (Data 타입).
    /// 이미지 변경 시 UserDefaults에 저장하고 위젯을 업데이트합니다.
    @Published var backgroundImageData: Data? {
        didSet {
            defaults.set(backgroundImageData, forKey: "backgroundImageData")
            WidgetCenter.shared.reloadAllTimelines() // 이미지 변경 시 위젯 업데이트 요청
        }
    }

    // MARK: - Initialization

    /// `UserSettings` 클래스의 초기화 메서드.
    /// UserDefaults에서 기존 설정 값을 로드하거나, 값이 없을 경우 기본값을 설정합니다.
    init() {
        self.nickname = defaults.string(forKey: "nickname") ?? "김건우"
        self.goal = defaults.string(forKey: "goal") ?? "취업"
        self.font = defaults.string(forKey: "font") ?? "고양일산 L"
        self.sound = defaults.string(forKey: "sound") ?? "기본"
        self.theme = defaults.string(forKey: "theme") ?? "라이트"
        self.backgroundImageData = defaults.data(forKey: "backgroundImageData")
    }

    // MARK: - Public Methods

    /// 현재 사용자 설정 값을 `UserProfile` 구조체로 반환합니다.
    /// - Returns: 현재 설정 값을 담고 있는 UserProfile 인스턴스.
    func profile() -> UserProfile {
        return UserProfile(nickname: nickname, goal: goal, font: font, sound: sound, theme: theme)
    }

    /// 현재 설정된 테마에 따라 선호하는 `ColorScheme`을 반환합니다.
    /// - Returns: `theme` 프로퍼티가 "다크"이면 `.dark`, 그렇지 않으면 `.light`.
    var preferredColorScheme: ColorScheme {
        theme == "다크" ? .dark : .light
    }
    
    /// 선택된 폰트 이름에 따라 적절한 `Font` 객체를 반환합니다.
    /// - Parameter size: 적용할 폰트 크기.
    /// - Returns: 지정된 폰트 이름과 크기에 해당하는 `Font` 객체.
    func getCustomFont(size: CGFloat) -> Font {
        if font == "고양일산 L" {
            return Font.custom("Goyangilsan L", size: size)
        } else if font == "고양일산 R" {
            return Font.custom("Goyangilsan R", size: size)
        } else if font == "조선일보명조" {
            return Font.custom("ChosunilboNM", size: size)
        } else {
            return .system(size: size) // 등록되지 않은 폰트거나 기본값일 경우 시스템 폰트 사용
        }
    }

    /// 앱 전반적으로 사용될 기본 폰트 스타일 (기본 크기 30pt 적용).
    /// `getCustomFont` 메서드를 사용하여 현재 `font` 설정에 맞는 폰트를 반환합니다.
    var fontStyle: Font {
        return getCustomFont(size: 30) // 앱의 주요 텍스트에 적용될 기본 폰트 크기
    }
}
