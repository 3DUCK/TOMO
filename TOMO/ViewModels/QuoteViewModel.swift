// MARK: - QuoteViewModel.swift
import Foundation
import Combine
import WidgetKit // WidgetCenter를 사용하기 위해 import

class QuoteViewModel: ObservableObject {
    @Published var todayQuote: String = "불러오는 중..." // 오늘의 문구
    @Published var allQuotes: [Quote] = [] // 모든 문구 기록을 저장할 배열

    private let userDefaults = UserDefaults(suiteName: AppConstants.appGroupID)!
    private let allQuotesKey = "allQuotesData" // 모든 문구 기록을 Data로 저장할 키

    // 기존 AppConstants.todayQuoteKey와 AppConstants.todayQuoteDateKey 사용
    private let todayQuoteTextKey = AppConstants.todayQuoteKey
    private let todayQuoteDateKey = AppConstants.todayQuoteDateKey


    init() {
        print("QuoteViewModel 🚀 init: Initializing ViewModel.") // ✅ 추가된 디버그 로그
        // 앱 실행 시 저장된 모든 문구 기록 로드
        loadAllQuotes()

        // 오늘의 문구 로드 (기존 로직 유지)
        // 위젯과 앱이 동일한 오늘의 문구를 표시하도록 App Group UserDefaults를 사용
        if let savedQuoteText = userDefaults.string(forKey: todayQuoteTextKey),
           let savedQuoteDate = userDefaults.object(forKey: todayQuoteDateKey) as? Date {
            let calendar = Calendar.current
            // 오늘 날짜의 문구가 저장되어 있다면 사용
            if calendar.isDate(savedQuoteDate, inSameDayAs: Date()) {
                self.todayQuote = savedQuoteText
                print("QuoteViewModel ✅ init: Loaded saved todayQuote for today: \"\(savedQuoteText)\".") // ✅ 추가된 디버그 로그
            } else {
                // 저장된 문구가 오늘 날짜가 아니면 새로 불러오도록 초기화
                self.todayQuote = "새 문구 불러오는 중..."
                print("QuoteViewModel 🔄 init: Saved quote is old. Setting '새 문구 불러오는 중...' and calling fetchAndSaveTodayQuote().") // ✅ 추가된 디버그 로그
                fetchAndSaveTodayQuote() // 새 문구 로드 시도
            }
        } else {
            // 저장된 문구가 없으면 새로 불러오도록 초기화
            self.todayQuote = "새 문구 불러오는 중..."
            print("QuoteViewModel 🔄 init: No saved quote or date. Setting '새 문구 불러오는 중...' and calling fetchAndSaveTodayQuote().") // ✅ 추가된 디버그 로그
            fetchAndSaveTodayQuote() // 새 문구 로드 시도
        }
    }

    func fetchAndSaveTodayQuote() {
        print("QuoteViewModel ⚡️ fetchAndSaveTodayQuote: Attempting to fetch new quote.") // ✅ 추가된 디버그 로그
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastFetch = userDefaults.object(forKey: todayQuoteDateKey) as? Date
        let lastFetchDay = lastFetch.map { calendar.startOfDay(for: $0) }

        // 오늘 날짜의 문구가 이미 저장되어 있고, fetchAndSaveTodayQuote()가 다시 호출된 경우 (예: onAppear)
        // 이 로직은 init()에서 이미 처리되었을 가능성이 높으므로, 중복 호출 시 빠르게 종료하도록 최적화할 수 있습니다.
        if let lastFetchDay = lastFetchDay, calendar.isDate(today, inSameDayAs: lastFetchDay),
           let savedQuote = userDefaults.string(forKey: todayQuoteTextKey) {
            
            // `init`에서 이미 `todayQuote`를 설정했을 것이므로, 여기서는 불필요하게 다시 할당하지 않습니다.
            // 만약 `init`이 아닌 다른 곳에서 `fetchAndSaveTodayQuote`가 호출되었고, 이미 데이터가 있다면 여기서 종료합니다.
            print("QuoteViewModel ⏭️ fetchAndSaveTodayQuote: Today's quote already loaded. Skipping fetch.") // ✅ 추가된 디버그 로그
            return
        }

        // QuoteService를 통해 문구를 가져옵니다.
        QuoteService.shared.fetchTodayQuote { [weak self] quoteText in
            DispatchQueue.main.async { // Main Actor에서 UI 업데이트
                guard let self = self else { return }
                self.todayQuote = quoteText // @Published 속성 업데이트
                self.addOrUpdateQuoteRecord(text: quoteText, date: Date()) // 기록에 추가 또는 업데이트
                
                // 오늘 날짜와 문구를 UserDefaults에 저장
                self.userDefaults.set(quoteText, forKey: self.todayQuoteTextKey)
                self.userDefaults.set(today, forKey: self.todayQuoteDateKey)
                
                print("QuoteViewModel ✅ fetchAndSaveTodayQuote: Successfully fetched and set todayQuote: \"\(quoteText)\".") // ✅ 추가된 디버그 로그
                WidgetCenter.shared.reloadAllTimelines() // 위젯 업데이트 요청 (필요한 경우)
            }
        }
    }

    // 앱 실행 시 저장된 모든 문구 기록을 로드하는 함수
    func loadAllQuotes() {
        print("QuoteViewModel 💾 loadAllQuotes: Attempting to load all quotes.") // ✅ 추가된 디버그 로그
        if let savedData = userDefaults.data(forKey: allQuotesKey) {
            do {
                let decodedQuotes = try JSONDecoder().decode([Quote].self, from: savedData)
                self.allQuotes = decodedQuotes.sorted(by: { $0.date > $1.date }) // 최신 날짜순 정렬
                print("QuoteViewModel ✅ loadAllQuotes: Successfully loaded \(self.allQuotes.count) quotes.") // ✅ 추가된 디버그 로그
            } catch {
                print("QuoteViewModel ❌ loadAllQuotes: Error decoding all quotes: \(error.localizedDescription)") // ✅ 추가된 디버그 로그
                self.allQuotes = []
            }
        } else {
            print("QuoteViewModel ℹ️ loadAllQuotes: No saved allQuotes data found.") // ✅ 추가된 디버그 로그
            self.allQuotes = []
        }
    }

    // 모든 문구 기록을 UserDefaults에 저장하는 함수
    func saveAllQuotes() {
        print("QuoteViewModel 💾 saveAllQuotes: Attempting to save \(self.allQuotes.count) quotes.") // ✅ 추가된 디버그 로그
        do {
            let encodedData = try JSONEncoder().encode(allQuotes)
            userDefaults.set(encodedData, forKey: allQuotesKey)
            print("QuoteViewModel ✅ saveAllQuotes: Successfully saved all quotes.") // ✅ 추가된 디버그 로그
            // 위젯의 '오늘의 문구'와 '모든 문구'를 업데이트하기 위해 위젯 타임라인을 새로고침
            // WidgetCenter.shared.reloadAllTimelines() // 모든 문구 저장 시 항상 위젯을 업데이트할 필요는 없을 수 있음
        } catch {
            print("QuoteViewModel ❌ saveAllQuotes: Error encoding all quotes: \(error.localizedDescription)") // ✅ 추가된 디버그 로그
        }
    }

    // 새로운 문구를 기록에 추가하거나 기존 문구를 업데이트
    func addOrUpdateQuoteRecord(text: String, date: Date) {
        let calendar = Calendar.current
        // 오늘 날짜와 동일한 문구가 이미 있는지 확인
        if let index = allQuotes.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            // 이미 오늘 날짜의 문구가 있다면 텍스트만 업데이트 (메모, 감정은 그대로 유지)
            // 오늘 문구가 업데이트되면, 그 날짜의 기존 메모와 감정은 유지되어야 함
            allQuotes[index].text = text
            saveAllQuotes() // allQuotes를 직접 변경했으므로, saveAllQuotes 호출
            print("QuoteViewModel 📝 addOrUpdateQuoteRecord: Updated existing quote for \(date.formatted()). Text: \"\(text)\"") // ✅ 추가된 디버그 로그
        } else {
            // 없다면 새로운 문구 추가
            // 새로운 문구는 메모와 감정이 없는 상태로 추가됨
            let newQuote = Quote(id: UUID().uuidString, text: text, date: date, memo: nil, emotion: nil)
            allQuotes.append(newQuote)
            allQuotes.sort(by: { $0.date > $1.date }) // 추가 후 최신 날짜순 정렬
            saveAllQuotes() // 변경사항 저장
            print("QuoteViewModel ➕ addOrUpdateQuoteRecord: Added new quote for \(date.formatted()). Text: \"\(text)\"") // ✅ 추가된 디버그 로그
        }
    }

    // 특정 Quote의 메모 및 감정 업데이트
    func updateQuoteMemoAndEmotion(id: String, memo: String?, emotion: String?) {
        print("QuoteViewModel ✏️ updateQuoteMemoAndEmotion: Updating quote with ID: \(id)") // ✅ 추가된 디버그 로그
        if let index = allQuotes.firstIndex(where: { $0.id == id }) {
            allQuotes[index].memo = memo
            allQuotes[index].emotion = emotion
            saveAllQuotes() // 변경사항 저장
            print("QuoteViewModel ✅ updateQuoteMemoAndEmotion: Successfully updated quote ID: \(id). Memo: \"\(memo ?? "nil")\", Emotion: \"\(emotion ?? "nil")\"") // ✅ 추가된 디버그 로그
        } else {
            print("QuoteViewModel ❌ updateQuoteMemoAndEmotion: Quote with ID \(id) not found.") // ✅ 추가된 디버그 로그
        }
    }
}
