//
// Quote.swift
//
// 이 파일은 앱에서 사용되는 '문구' 데이터 모델을 정의하는 구조체입니다.
// Firestore 데이터베이스와의 연동(저장 및 로드)을 지원하며,
// 앱의 다양한 기능(예: 위젯, 기록, 편집)에서 문구 정보를 효율적으로 관리할 수 있도록
// Codable, Identifiable, Equatable 프로토콜을 준수합니다.
//
// 문구의 내용, 생성 날짜, 메모, 감정, 생성 주체(AI 모델), 스타일, 목표,
// 그리고 특정 주제(취업, 다이어트, 자기계발, 학업)별 문구 필드를 포함합니다.
//

import Foundation
import FirebaseFirestore // Firestore Timestamp를 Date로 변환하기 위해 필요합니다.

/// 앱의 '문구' 데이터를 나타내는 구조체.
/// Identifiable: SwiftUI 리스트에서 고유하게 식별 가능하게 합니다.
/// Codable: UserDefaults나 Firebase에 저장/로드할 수 있도록 합니다.
/// Equatable: 두 Quote 객체를 비교할 수 있도록 합니다.
struct Quote: Identifiable, Codable, Equatable {
    let id: String // 문구의 고유 ID (Firestore 문서 ID와 연동)
    var text: String // 문구 내용
    var date: Date // 문구가 생성된 날짜 및 시간
    var memo: String? // 사용자의 메모 (선택 사항)
    var emotion: String? // 문구와 관련된 감정 이모티콘 (선택 사항)
    var generatedBy: String? // 문구를 생성한 주체 (예: "OpenAI", "Gemini", "User")
    var style: String? // 문구의 스타일 (예: "감성적", "실용적", "동기 부여")
    var goal: String? // 명언의 목표 주제 (예: "employment", "diet", "selfdev", "study")

    // Firestore 신규 구조에 대응하는 4가지 주제별 문구 필드.
    // 각 주제에 대한 특정 문구를 저장할 수 있습니다.
    var employment: String?
    var diet: String?
    var selfdev: String?
    var study: String?

    // MARK: - Equatable Protocol

    /// 두 Quote 객체가 동일한지 비교하는 메서드.
    /// id, text, date(같은 날짜인지), memo, emotion, generatedBy, style 필드를 비교합니다.
    static func == (lhs: Quote, rhs: Quote) -> Bool {
        lhs.id == rhs.id &&
        lhs.text == rhs.text &&
        Calendar.current.isDate(lhs.date, inSameDayAs: rhs.date) && // 날짜는 같은 날짜인지 확인 (시간은 무시)
        lhs.memo == rhs.memo &&
        lhs.emotion == rhs.emotion &&
        lhs.generatedBy == rhs.generatedBy &&
        lhs.style == rhs.style
        // goal, employment, diet, selfdev, study 필드는 Equatable 비교에서 제외됨.
        // 필요에 따라 추가할 수 있습니다.
    }

    // MARK: - Initializers

    /// Firestore `DocumentSnapshot`으로부터 `Quote` 객체를 생성하는 초기화 메서드.
    /// 스냅샷의 데이터를 파싱하여 Quote 속성에 매핑합니다.
    /// - Parameter document: Firestore DocumentSnapshot 인스턴스.
    /// - Returns: DocumentSnapshot으로부터 생성된 Quote 객체, 또는 데이터가 유효하지 않을 경우 nil.
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else {
            print("Error: Document data is nil for document ID \(document.documentID).") // 디버깅 로그
            return nil
        }
        
        self.id = document.documentID
        self.text = data["text"] as? String ?? "문구 없음" // 'text' 필드가 없으면 기본값 설정

        // Firestore Timestamp를 Swift Date 객체로 변환
        if let timestamp = data["date"] as? Timestamp {
            self.date = timestamp.dateValue()
        } else {
            // 'date' 필드가 없거나 Timestamp 타입이 아닐 경우 현재 날짜를 사용하고 경고 출력
            self.date = Date()
            print("Warning: 'date' field missing or not a Timestamp in document \(document.documentID). Using current date.")
        }
        
        self.memo = data["memo"] as? String
        self.emotion = data["emotion"] as? String
        self.generatedBy = data["generatedBy"] as? String
        self.style = data["style"] as? String
        self.goal = data["goal"] as? String

        // 4가지 주제별 문구 필드 파싱
        self.employment = data["employment"] as? String
        self.diet = data["diet"] as? String
        self.selfdev = data["selfdev"] as? String
        self.study = data["study"] as? String
    }

    /// Codable 프로토콜 준수를 위한 일반 초기화 메서드 (주로 인메모리 또는 UserDefaults 저장/로드용).
    /// 모든 Quote 속성을 인자로 받아 객체를 생성합니다.
    /// `id`는 기본적으로 UUID로 자동 생성됩니다.
    init(
        id: String = UUID().uuidString, // 기본값: 새로운 UUID 문자열
        text: String,
        date: Date,
        memo: String?,
        emotion: String?,
        generatedBy: String?,
        style: String?,
        goal: String?,
        employment: String? = nil, // 기본값: nil
        diet: String? = nil,       // 기본값: nil
        selfdev: String? = nil,    // 기본값: nil
        study: String? = nil       // 기본값: nil
    ) {
        self.id = id
        self.text = text
        self.date = date
        self.memo = memo
        self.emotion = emotion
        self.generatedBy = generatedBy
        self.style = style
        self.goal = goal
        self.employment = employment
        self.diet = diet
        self.selfdev = selfdev
        self.study = study
    }
}
