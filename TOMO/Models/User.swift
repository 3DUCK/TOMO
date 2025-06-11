// MARK: - User.swift (UserSettings 클래스 부분)
import Foundation
import SwiftUI
import WidgetKit // WidgetCenter를 사용하기 위해 import 필요

struct UserProfile: Codable {
    var nickname: String
    var goal: String
    var font: String
    var sound: String
    var theme: String
}

class UserSettings: ObservableObject {
    private let defaults = UserDefaults(suiteName: AppConstants.appGroupID)!

    @Published var nickname: String {
        didSet { defaults.set(nickname, forKey: "nickname"); WidgetCenter.shared.reloadAllTimelines() }
    }
    @Published var goal: String {
        didSet { defaults.set(goal, forKey: "goal"); WidgetCenter.shared.reloadAllTimelines() }
    }
    @Published var font: String {
        didSet { defaults.set(font, forKey: "font"); WidgetCenter.shared.reloadAllTimelines() }
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
        self.nickname = defaults.string(forKey: "nickname") ?? "Guest"
        self.goal = defaults.string(forKey: "goal") ?? "취업"
        self.font = defaults.string(forKey: "font") ?? "고양일산 L"
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

    var fontStyle: Font {
        if font == "고양일산 L" {
            return Font.custom("Goyangilsan L", size: 20)
        } else if font == "고양일산 R" {
            return Font.custom("Goyangilsan R", size: 20)
        } else {
            return .body
        }
    }
}
