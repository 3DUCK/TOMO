// QuoteService.swift
import Foundation
import FirebaseFirestore // Firestore 사용을 위해 임포트

class QuoteService {
    static let shared = QuoteService()

    private let db = Firestore.firestore() // Firestore 인스턴스

    // 오늘의 문구를 Firestore에서 가져오는 함수 (goal별)
    func fetchTodayQuote(forGoal goal: String, completion: @escaping (String) -> Void) {
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let docId = dateFormatter.string(from: today) // 오늘 날짜를 문서 ID로 사용 (예: "2025-06-12")

        let docRef = db.collection("dailyQuotes").document(docId)
        let fieldMap: [String: String] = [
            "취업": "employment",
            "다이어트": "diet",
            "자기계발": "selfdev",
            "학업": "study"
        ]
        let field = fieldMap[goal] ?? "employment"

        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // 문서가 존재하면 goal에 해당하는 필드를 가져옴
                if let text = document.data()?[field] as? String {
                    print("QuoteService 🌐 fetchTodayQuote: Successfully fetched quote from Firestore for \(docId): \"\(text)\"")
                    completion(text)
                } else {
                    // 해당 필드가 없는 경우
                    let errorMessage = "Firestore 문서에 '\(field)' 필드가 없습니다: \(docId)"
                    print("QuoteService ⚠️ fetchTodayQuote: \(errorMessage)")
                    completion("문구를 불러올 수 없습니다.") // 사용자에게 표시할 기본 문구
                }
            } else if let error = error {
                // 문서 가져오기 중 오류 발생
                print("QuoteService ❌ fetchTodayQuote: Error fetching document for \(docId): \(error.localizedDescription)")
                completion("문구를 불러오는 중 오류 발생.") // 사용자에게 표시할 기본 문구
            } else {
                // 문서가 존재하지 않는 경우 (아직 생성되지 않음)
                print("QuoteService 🚫 fetchTodayQuote: Document for \(docId) does not exist in Firestore.")
                completion("오늘의 문구가 아직 준비되지 않았습니다.") // 사용자에게 표시할 기본 문구
            }
        }
    }

    // 모든 문구를 Firestore에서 가져오는 함수 (히스토리 화면용)
    func fetchAllQuotes(completion: @escaping ([Quote]) -> Void) {
        db.collection("dailyQuotes").order(by: "date", descending: true).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("QuoteService ❌ fetchAllQuotes: Error getting documents: \(error.localizedDescription)")
                completion([])
            } else {
                var quotes: [Quote] = []
                for document in querySnapshot!.documents {
                    if var quote = Quote(document: document) {
                        // date를 KST 기준의 0시로 변환
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
    
    // MARK: - 기존 UserDefaults 관련 함수는 이제 필요 없거나 ViewModel로 이동 가능
    // 이 함수들은 더 이상 QuoteService에서 직접적으로 사용되지 않습니다.
    // QuoteViewModel에서 UserDefaults를 계속 사용할 경우, 해당 함수는 ViewModel에 두는 것이 좋습니다.
    // func saveQuoteToAppGroup(_ quote: String) { ... }
    // func loadQuoteFromAppGroup() -> String { ... }

    // MARK: - 메모 및 감정 업데이트 (Firestore 업데이트)
    // 이 함수는 사용자가 앱 내에서 메모나 감정을 업데이트할 때 Firestore를 업데이트하는 데 사용됩니다.
    func updateQuoteInFirestore(quote: Quote, completion: @escaping (Error?) -> Void) {
        let docRef = db.collection("dailyQuotes").document(quote.id)
        
        // nil 값은 Firestore에서 필드를 삭제하지 않습니다.
        // 특정 필드를 업데이트하려면 merge: true를 사용하거나, 전체 문서를 덮어쓰려면 merge: false (기본값)를 사용합니다.
        // 여기서는 기존 데이터는 유지하고, memo와 emotion만 업데이트하므로 merge: true가 적절합니다.
        let data: [String: Any?] = [
            "memo": quote.memo,
            "emotion": quote.emotion
        ]
        
        docRef.updateData(data) { error in
            if let error = error {
                print("QuoteService ❌ updateQuoteInFirestore: Error updating quote \(quote.id): \(error.localizedDescription)")
                completion(error)
            } else {
                print("QuoteService 💾 updateQuoteInFirestore: Successfully updated quote \(quote.id). Memo: \(quote.memo ?? "nil"), Emotion: \(quote.emotion ?? "nil")")
                completion(nil)
            }
        }
    }
}
