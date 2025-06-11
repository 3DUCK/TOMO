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

// UserProfile 등 다른 코드는 그대로 유지

class UserSettings: ObservableObject {
    // 기존 @AppStorage는 앱 그룹과 연동되지 않습니다.
    // @AppStorage("nickname") var nickname: String = "Guest"
    // @AppStorage("goal") var goal: String = "취업"
    // @AppStorage("font") var font: String = "산세리프"
    // @AppStorage("sound") var sound: String = "기본"
    // @AppStorage("theme") var theme: String = "라이트"

    // 앱 그룹 UserDefaults 인스턴스 생성
    private let defaults = UserDefaults(suiteName: AppConstants.appGroupID)!

    // 각 설정값을 앱 그룹 UserDefaults에서 읽고 쓰도록 변경
    @Published var nickname: String {
        didSet { defaults.set(nickname, forKey: "nickname") }
    }
    @Published var goal: String {
        didSet { defaults.set(goal, forKey: "goal") }
    }
    @Published var font: String {
        didSet { defaults.set(font, forKey: "font") }
    }
    @Published var sound: String {
        didSet { defaults.set(sound, forKey: "sound") }
    }
    @Published var theme: String {
        didSet { defaults.set(theme, forKey: "theme") }
    }
    
    // 배경 이미지 데이터를 Data? 타입으로 저장합니다.
    // UIImage는 직접 UserDefaults에 저장할 수 없으므로 Data로 변환
    @Published var backgroundImageData: Data? {
        didSet {
            defaults.set(backgroundImageData, forKey: "backgroundImageData")
        }
    }


    init() {
        // 초기값 로드
        self.nickname = defaults.string(forKey: "nickname") ?? "Guest"
        self.goal = defaults.string(forKey: "goal") ?? "취업"
        self.font = defaults.string(forKey: "font") ?? "고양일산 L"
        self.sound = defaults.string(forKey: "sound") ?? "기본"
        self.theme = defaults.string(forKey: "theme") ?? "라이트"
    }

    func profile() -> UserProfile {
        return UserProfile(nickname: nickname, goal: goal, font: font, sound: sound, theme: theme)
    }

    var preferredColorScheme: ColorScheme {
        theme == "다크" ? .dark : .light
    }

    var fontStyle: Font {
        // 이 부분을 커스텀 폰트 로드로 수정합니다:
        if font == "고양일산 L" { // "산세리프" 선택 시 Goyangilsan L 폰트 적용
            // PostScript 이름이 'GoyangilsanL' 또는 'GoyangilsanL-Regular'인지 확인 후 사용
            return Font.custom("Goyangilsan L", size: 20) // 폰트 크기는 필요에 따라 조절
            // 만약 정확한 PostScript 이름이 'GoyangilsanL-Regular'라면:
            // return Font.custom("GoyangilsanL-Regular", size: 17)
        } else if font == "고양일산 R" { // "세리프" 선택 시 다른 폰트 적용 (예: 시스템 기본 세리프 또는 다른 커스텀)
            // 여기서는 예시로 시스템 .body 폰트를 사용합니다.
            // 만약 다른 커스텀 세리프 폰트가 있다면 Font.custom("세리프_폰트_이름", size: 17) 사용
            return Font.custom("Goyangilsan R", size: 20) // 혹은 .system(size: 17, design: .serif)
        } else {
            // 기본값 (혹은 오류 처리)
            return .body
        }
    }
}
