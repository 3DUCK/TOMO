// MARK: - User.swift
import Foundation
import SwiftUI

struct UserProfile: Codable {
    var nickname: String
    var goal: String
    var font: String
    var sound: String
    var theme: String
    // backgroundImage는 로컬에 저장하거나 URL로 관리
}

class UserSettings: ObservableObject {
    @AppStorage("nickname") var nickname: String = "Guest"
    @AppStorage("goal") var goal: String = "취업"
    @AppStorage("font") var font: String = "산세리프"
    @AppStorage("sound") var sound: String = "기본"
    @AppStorage("theme") var theme: String = "라이트"

    func profile() -> UserProfile {
        return UserProfile(nickname: nickname, goal: goal, font: font, sound: sound, theme: theme)
    }

    var preferredColorScheme: ColorScheme {
        theme == "다크" ? .dark : .light
    }

    var fontStyle: Font {
        font == "세리프" ? .title3.weight(.medium) : .title3
    }
}
