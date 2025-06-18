//
// QuoteService.swift
//
// 이 파일은 Firebase Firestore 데이터베이스와 상호작용하여
// 앱의 '문구(Quote)' 데이터를 관리하는 서비스 클래스입니다.
//
// 주요 기능:
// - 오늘의 문구 가져오기: 사용자의 목표(goal)에 따라 오늘 날짜의 문구를 Firestore에서 조회합니다.
// - 모든 문구 가져오기: 앱의 기록 화면 등에 사용될 모든 문구를 Firestore에서 가져옵니다.
// - 문구 업데이트: 기존 문구의 메모나 감정 정보를 Firestore에 업데이트합니다.
//
// 이 서비스는 Firestore 데이터베이스와의 통신을 캡슐화하여,
// 다른 뷰 모델이나 뷰에서 데이터 로직에 직접 접근하지 않고 일관된 방식으로 문구 데이터를
// 관리할 수 있도록 돕습니다.
//

import Foundation
import FirebaseFirestore // Firestore 사용을 위해 임포트

/// Firebase Firestore와 상호작용하여 문구(Quote) 데이터를 관리하는 서비스 클래스.
class QuoteService {
    /// QuoteService의 싱글톤 인스턴스.
    static let shared = QuoteService()

    /// Firestore 데이터베이스 인스턴스.
    private let db = Firestore.firestore()

    // MARK: - Fetching Quotes

    /// 오늘의 문구를 Firestore에서 가져오는 함수 (사용자 목표(goal)별).
    /// 문서는 `yyyy-MM-dd` 형식의 날짜를 ID로 사용하고, 각 목표 필드를 포함합니다.
    /// - Parameters:
    ///   - goal: 가져올 문구의 목표 (예: "취업", "다이어트").
    ///   - completion: 문구를 가져온 후 호출될 클로저. (String) -> Void 형태이며, 결과 문구를 전달합니다.
    func fetchTodayQuote(forGoal goal: String, completion: @escaping (String) -> Void) {
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        // 오늘 날짜를 문서 ID로 사용 (예: "2025-06-12")
        let docId = dateFormatter.string(from: today)

        let docRef = db.collection("dailyQuotes").document(docId)
        
        // 사용자 목표에 따른 Firestore 필드 매핑
        let fieldMap: [String: String] = [
            "취업": "employment",
            "다이어트": "diet",
            "자기계발": "selfdev",
            "학업": "study"
        ]
        // 매핑된 필드 이름을 가져오거나, 기본값으로 "employment"를 사용합니다.
        let field = fieldMap[goal] ?? "employment"

        docRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return } // self 캡처 방지 및 nil 체크
            
            if let document = document, document.exists {
                // 문서가 존재하면 goal에 해당하는 필드를 가져옴
                if let text = document.data()?[field] as? String {
                    print("QuoteService 🌐 fetchTodayQuote: Successfully fetched quote from Firestore for \(docId) - Field '\(field)': \"\(text)\"")
                    completion(text)
                } else {
                    // 해당 필드가 없는 경우
                    let errorMessage = "Firestore 문서 '\(docId)'에 '\(field)' 필드가 없거나 올바른 타입이 아닙니다."
                    print("QuoteService ⚠️ fetchTodayQuote: \(errorMessage)")
                    completion("문구를 불러올 수 없습니다.") // 사용자에게 표시할 기본 문구
                }
            } else if let error = error {
                // 문서 가져오기 중 오류 발생
                print("QuoteService ❌ fetchTodayQuote: Error fetching document for \(docId): \(error.localizedDescription)")
                completion("문구를 불러오는 중 오류 발생.") // 사용자에게 표시할 기본 문구
            } else {
                // 문서가 존재하지 않는 경우 (아직 해당 날짜의 문구가 생성되지 않음)
                print("QuoteService 🚫 fetchTodayQuote: Document for \(docId) does not exist in Firestore.")
                completion("오늘의 문구가 아직 준비되지 않았습니다.") // 사용자에게 표시할 기본 문구
            }
        }
    }

    /// 모든 문구를 Firestore에서 가져오는 함수 (주로 히스토리 화면용).
    /// 'date' 필드를 기준으로 최신 날짜부터 정렬하여 가져옵니다.
    /// - Parameter completion: 문구 목록을 가져온 후 호출될 클로저. ([Quote]) -> Void 형태이며, Quote 객체 배열을 전달합니다.
    func fetchAllQuotes(completion: @escaping ([Quote]) -> Void) {
        db.collection("dailyQuotes").order(by: "date", descending: true).getDocuments { [weak self] (querySnapshot, error) in
            guard self != nil else { return } // self 캡처 방지
            
            if let error = error {
                print("QuoteService ❌ fetchAllQuotes: Error getting documents: \(error.localizedDescription)")
                completion([]) // 오류 발생 시 빈 배열 반환
            } else {
                var quotes: [Quote] = []
                // 스냅샷의 각 문서를 Quote 객체로 변환
                for document in querySnapshot!.documents {
                    if var quote = Quote(document: document) {
                        // date를 한국 시간대(KST) 기준의 0시로 변환하여 날짜 일관성 유지
                        if let kst = TimeZone(identifier: "Asia/Seoul") {
                            var calendar = Calendar(identifier: .gregorian)
                            calendar.timeZone = kst
                            quote.date = calendar.startOfDay(for: quote.date)
                        }
                        quotes.append(quote)
                    }
                }
                print("QuoteService 🌐 fetchAllQuotes: Successfully fetched \(quotes.count) quotes from Firestore.")
                completion(quotes)
            }
        }
    }
    
    // MARK: - Updating Quotes

    /// 특정 문구의 메모 및 감정 정보를 Firestore에 업데이트하는 함수.
    /// - Parameters:
    ///   - quote: 업데이트할 문구(`Quote`) 객체. `id`, `memo`, `emotion` 필드가 사용됩니다.
    ///   - completion: 업데이트 완료 후 호출될 클로저. (Error?) -> Void 형태이며, 오류 발생 시 Error 객체를 전달합니다.
    func updateQuoteInFirestore(quote: Quote, completion: @escaping (Error?) -> Void) {
        let docRef = db.collection("dailyQuotes").document(quote.id)
        
        // 업데이트할 데이터 딕셔너리. `nil` 값은 해당 필드를 삭제하지 않고 유지합니다.
        // `merge: true` 옵션은 기존 문서의 다른 필드는 그대로 두고 지정된 필드만 업데이트합니다.
        let data: [String: Any?] = [
            "memo": quote.memo,
            "emotion": quote.emotion
        ]
        
        docRef.updateData(data as [String : Any]) { error in // `Any?`를 `Any`로 캐스팅 필요 (Firebase 요구사항)
            if let error = error {
                print("QuoteService ❌ updateQuoteInFirestore: Error updating quote \(quote.id): \(error.localizedDescription)")
                completion(error)
            } else {
                print("QuoteService 💾 updateQuoteInFirestore: Successfully updated quote \(quote.id). Memo: \(quote.memo ?? "nil"), Emotion: \(quote.emotion ?? "nil")")
                completion(nil)
            }
        }
    }
    
    // MARK: - Deprecated/Moved Functions (주석 처리 또는 제거 권장)
    
    // 이전에 UserDefaults 관련 함수는 이제 필요 없거나 ViewModel로 이동 가능합니다.
    // QuoteViewModel에서 UserDefaults를 계속 사용할 경우, 해당 함수는 ViewModel에 두는 것이 좋습니다.
    /*
    func saveQuoteToAppGroup(_ quote: String) {
        // 이 로직은 이제 QuoteViewModel 또는 다른 적절한 곳으로 이동되어야 합니다.
    }
    
    func loadQuoteFromAppGroup() -> String {
        // 이 로직은 이제 QuoteViewModel 또는 다른 적절한 곳으로 이동되어야 합니다.
        return ""
    }
    */
}
