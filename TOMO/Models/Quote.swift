// Quote.swift
import Foundation

struct Quote: Identifiable, Codable, Equatable {
    let id: String // 고유 ID
    var text: String // 문구 내용
    var date: Date // 문구가 생성된 날짜
    var memo: String? // 메모 (선택 사항)
    var emotion: String? // 감정 이모티콘 (선택 사항)

    // Equatable 프로토콜 구현: 두 Quote 객체가 동일한지 비교 (날짜는 같은 날인지, 다른 필드는 값 동일한지)
    static func == (lhs: Quote, rhs: Quote) -> Bool {
        lhs.id == rhs.id &&
        lhs.text == rhs.text &&
        Calendar.current.isDate(lhs.date, inSameDayAs: rhs.date) && // 날짜는 같은 날짜인지 확인
        lhs.memo == rhs.memo &&
        lhs.emotion == rhs.emotion
    }
}
