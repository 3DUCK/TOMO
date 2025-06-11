// QuoteService.swift
import Foundation

class QuoteService {
    static let shared = QuoteService()

    func fetchTodayQuote(completion: @escaping (String) -> Void) {
        // 🚧 나중에 Firebase로 대체할 부분
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let quote = "허세말고 무게, 감정말고  방향, 소리말고 결과"
            self.saveQuoteToAppGroup(quote)
            completion(quote)
        }
    }

    func saveQuoteToAppGroup(_ quote: String) {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        defaults?.set(quote, forKey: AppConstants.todayQuoteKey)
    }

    func loadQuoteFromAppGroup() -> String {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        return defaults?.string(forKey: AppConstants.todayQuoteKey) ?? "문구를 불러올 수 없습니다."
    }
}
