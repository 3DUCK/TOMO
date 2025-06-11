import Foundation
import Combine
import WidgetKit // WidgetCenter를 사용하기 위해 import

class QuoteViewModel: ObservableObject {
    @Published var todayQuote: String = "불러오는 중..."
    @Published var allQuotes: [Quote] = [] // 모든 문구 기록을 저장할 배열

    private let userDefaults = UserDefaults(suiteName: AppConstants.appGroupID)!
    private let allQuotesKey = "allQuotesData" // 모든 문구 기록을 Data로 저장할 키

    // 기존 AppConstants.todayQuoteKey와 AppConstants.todayQuoteDateKey 사용
    private let todayQuoteTextKey = AppConstants.todayQuoteKey
    private let todayQuoteDateKey = AppConstants.todayQuoteDateKey


    init() {
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
                // ✅ 이 부분이 추가/수정되었습니다.
                // UserDefaults에서 오늘 문구를 가져왔을 때, allQuotes에도 해당 문구를 반영합니다.
                addOrUpdateQuoteRecord(text: savedQuoteText, date: Date())
            } else {
                // 저장된 문구가 오늘 날짜가 아니면 새로 불러오도록 초기화
                self.todayQuote = "새 문구 불러오는 중..."
                fetchAndSaveTodayQuote() // 새 문구 로드 시도
            }
        } else {
            // 저장된 문구가 전혀 없으면 새로 불러오도록 초기화
            self.todayQuote = "첫 문구 로드 중..."
            fetchAndSaveTodayQuote()
        }
        print("QuoteViewModel 🚀 init: Initializing ViewModel. Final todayQuote: \"\(todayQuote)\"")
    }

    // 모든 문구 기록 로드
    func loadAllQuotes() {
        if let savedQuotesData = userDefaults.data(forKey: allQuotesKey) {
            do {
                let decoder = JSONDecoder()
                // 디코딩 시 날짜 형식을 명확히 지정하거나 기본값을 사용
                // decoder.dateDecodingStrategy = .iso8601 // 필요에 따라 설정
                allQuotes = try decoder.decode([Quote].self, from: savedQuotesData)
                print("QuoteViewModel 📦 loadAllQuotes: Loaded \(allQuotes.count) quotes.")
            } catch {
                print("Error decoding all quotes: \(error.localizedDescription)")
                allQuotes = [] // 오류 발생 시 빈 배열로 초기화
            }
        } else {
            print("QuoteViewModel 📦 loadAllQuotes: No saved quotes found.")
        }
    }

    // 모든 문구 기록 저장
    func saveAllQuotes() {
        do {
            let encoder = JSONEncoder()
            // 인코딩 시 날짜 형식을 명확히 지정하거나 기본값을 사용
            // encoder.dateEncodingStrategy = .iso8601 // 필요에 따라 설정
            let encodedData = try encoder.encode(allQuotes)
            userDefaults.set(encodedData, forKey: allQuotesKey)
            print("QuoteViewModel 💾 saveAllQuotes: Saved \(allQuotes.count) quotes.")
            // 위젯 업데이트를 트리거할 필요가 있다면 여기서 호출
            // WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error encoding all quotes: \(error.localizedDescription)")
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
            print("QuoteViewModel 📝 addOrUpdateQuoteRecord: Updated quote for date \(date.formatted()). New text: \"\(text)\"")
        } else {
            // 없다면 새로운 문구 추가
            // 새로운 문구는 메모와 감정이 없는 상태로 추가됨
            let newQuote = Quote(id: UUID().uuidString, text: text, date: date, memo: nil, emotion: nil)
            allQuotes.append(newQuote)
            allQuotes.sort(by: { $0.date > $1.date }) // 추가 후 최신 날짜순 정렬
            saveAllQuotes() // 변경사항 저장
            print("QuoteViewModel ✨ addOrUpdateQuoteRecord: Added new quote for date \(date.formatted()). Text: \"\(text)\"")
        }
    }

    // 특정 Quote의 메모 및 감정 업데이트
    func updateQuoteMemoAndEmotion(id: String, memo: String?, emotion: String?) {
        if let index = allQuotes.firstIndex(where: { $0.id == id }) {
            allQuotes[index].memo = memo == "" ? nil : memo // 빈 문자열이면 nil로 저장
            allQuotes[index].emotion = emotion
            saveAllQuotes()
            print("QuoteViewModel ✍️ updateQuoteMemoAndEmotion: Updated memo for ID \(id). Memo: \"\(memo ?? "nil")\", Emotion: \(emotion ?? "nil")")
        } else {
            print("QuoteViewModel ⚠️ updateQuoteMemoAndEmotion: Quote with ID \(id) not found.")
        }
    }

    // 오늘의 문구를 QuoteService를 통해 가져오고 UserDefaults에 저장
    func fetchAndSaveTodayQuote() {
        QuoteService.shared.fetchTodayQuote { [weak self] fetchedQuoteText in
            guard let self = self else { return }
            print("QuoteViewModel 🌐 fetchAndSaveTodayQuote: Fetched new quote: \"\(fetchedQuoteText)\"")
            DispatchQueue.main.async {
                self.todayQuote = fetchedQuoteText
                self.userDefaults.set(fetchedQuoteText, forKey: self.todayQuoteTextKey)
                self.userDefaults.set(Date(), forKey: self.todayQuoteDateKey)
                self.addOrUpdateQuoteRecord(text: fetchedQuoteText, date: Date()) // fetched text로 기록 업데이트
                WidgetCenter.shared.reloadAllTimelines() // 위젯 업데이트
            }
        }
    }
}
