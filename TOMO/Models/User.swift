// MARK: - UserSettings.swift (수정된 UserSettings 클래스)
import Foundation
import SwiftUI
import WidgetKit // WidgetCenter를 사용하기 위해 import 필요

struct UserProfile: Codable {
    var nickname: String
    var goal: String
    var font: String // 이 'font' 프로퍼티를 폰트 이름을 저장하는 용도로 사용
    var sound: String
    var theme: String
}

class UserSettings: ObservableObject {
    // @AppStorage("font") var fontSetting: String = "고양일산 L" // 이 프로퍼티는 제거하거나 다른 용도로 사용

    private let defaults = UserDefaults(suiteName: AppConstants.appGroupID)!

    @Published var nickname: String {
        didSet { defaults.set(nickname, forKey: "nickname"); WidgetCenter.shared.reloadAllTimelines() }
    }
    @Published var goal: String {
        didSet { defaults.set(goal, forKey: "goal"); WidgetCenter.shared.reloadAllTimelines() }
    }
    // 이 'font' 프로퍼티가 실제 선택된 폰트 이름(String)을 저장하고 관리합니다.
    @Published var font: String {
        didSet {
            defaults.set(font, forKey: "font")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    @Published var sound: String {
        didSet { defaults.set(sound, forKey: "sound"); WidgetCenter.shared.reloadAllTimelines() }
    }
    @Published var theme: String {
        didSet { defaults.set(theme, forKey: "theme"); WidgetCenter.shared.reloadAllTimelines() }
    }
    
    @Published var backgroundImageData: Data? {
        didSet {
            defaults.set(backgroundImageData, forKey: "backgroundImageData")
            WidgetCenter.shared.reloadAllTimelines() // 이미지 변경 시 위젯 업데이트 요청
        }
    }

    init() {
        self.nickname = defaults.string(forKey: "nickname") ?? "김건우"
        self.goal = defaults.string(forKey: "goal") ?? "취업"
        self.font = defaults.string(forKey: "font") ?? "고양일산 L" // "font" 키로 UserDefaults에서 로드
        self.sound = defaults.string(forKey: "sound") ?? "기본"
        self.theme = defaults.string(forKey: "theme") ?? "라이트"
        self.backgroundImageData = defaults.data(forKey: "backgroundImageData")
    }

    func profile() -> UserProfile {
        return UserProfile(nickname: nickname, goal: goal, font: font, sound: sound, theme: theme)
    }

    var preferredColorScheme: ColorScheme {
        theme == "다크" ? .dark : .light
    }
    
    // **수정된 부분:** 폰트 이름에 따라 실제 Font 객체를 반환하는 함수 (크기를 인자로 받음)
    func getCustomFont(size: CGFloat) -> Font {
        if font == "고양일산 L" { // @Published font 프로퍼티 사용
            return Font.custom("Goyangilsan L", size: size)
        } else if font == "고양일산 R" {
            return Font.custom("Goyangilsan R", size: size)
        } else if font == "조선일보명조" {
            return Font.custom("ChosunilboNM", size: size)
        } else {
            return .system(size: size) // 기본 시스템 폰트도 크기 적용
        }
    }

    // 앱 전반적으로 사용될 기본 폰트 스타일 (기본 크기 지정)
    var fontStyle: Font {
        return getCustomFont(size: 30) // 기본 크기 30pt
    }
}
