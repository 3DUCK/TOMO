// Quote.swift
import Foundation
import FirebaseFirestore // Firestore Timestamp를 Date로 변환하기 위해 필요할 수 있습니다.

struct Quote: Identifiable, Codable, Equatable {
    let id: String // 고유 ID (Firestore 문서 ID와 연동 가능)
    var text: String // 문구 내용
    var date: Date // 문구가 생성된 날짜
    var memo: String? // 메모 (선택 사항)
    var emotion: String? // 감정 이모티콘 (선택 사항)
    var generatedBy: String? // 생성 주체 (OpenAI, Gemini 등) - Firestore 필드 추가
    var style: String? // 문구 스타일 (감성적, 실행적 등) - Firestore 필드 추가

    // Equatable 프로토콜 구현: 두 Quote 객체가 동일한지 비교 (날짜는 같은 날인지, 다른 필드는 값 동일한지)
    static func == (lhs: Quote, rhs: Quote) -> Bool {
        lhs.id == rhs.id &&
        lhs.text == rhs.text &&
        Calendar.current.isDate(lhs.date, inSameDayAs: rhs.date) && // 날짜는 같은 날짜인지 확인
        lhs.memo == rhs.memo &&
        lhs.emotion == rhs.emotion &&
        lhs.generatedBy == rhs.generatedBy && // 추가된 필드 비교
        lhs.style == rhs.style                // 추가된 필드 비교
    }

    // Firestore에서 데이터를 디코딩하기 위한 초기화 메서드 (선택 사항이지만 유용)
    // Firestore DocumentSnapshot에서 바로 Quote 객체를 생성할 수 있게 해줍니다.
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        // id는 문서 ID로 설정
        self.id = document.documentID
        
        // Firestore 필드로부터 값 추출
        self.text = data["text"] as? String ?? "문구 없음" // 기본값 제공
        
        // Firestore Timestamp를 Date로 변환
        if let timestamp = data["date"] as? Timestamp {
            self.date = timestamp.dateValue()
        } else {
            // date 필드가 없거나 Timestamp가 아닌 경우 오늘 날짜로 대체
            self.date = Date()
            print("Warning: 'date' field missing or not a Timestamp in document \(document.documentID). Using current date.")
        }
        
        self.memo = data["memo"] as? String
        self.emotion = data["emotion"] as? String
        self.generatedBy = data["generatedBy"] as? String
        self.style = data["style"] as? String
    }
    
    // Codable을 위한 init (UserDefaults 저장/로드를 위해 필요)
    // Firestore에서 가져온 Quote 객체는 이 init을 통해 다시 인코딩될 수 있습니다.
    init(id: String = UUID().uuidString, text: String, date: Date, memo: String?, emotion: String?, generatedBy: String?, style: String?) {
        self.id = id
        self.text = text
        self.date = date
        self.memo = memo
        self.emotion = emotion
        self.generatedBy = generatedBy
        self.style = style
    }
}
