// QuoteViewModel.swift
import Foundation
import Combine
import WidgetKit
//import FirebaseFirestore // Firestore 사용을 위해 임포트 (QuoteService에서 사용하므로 필수는 아니지만 명시적으로)

class QuoteViewModel: ObservableObject {
    @Published var todayQuote: String = "불러오는 중..."
    @Published var allQuotes: [Quote] = [] // 모든 문구 기록을 저장할 배열

    private let userDefaults = UserDefaults(suiteName: AppConstants.appGroupID)!
    private let allQuotesKey = "allQuotesData" // 모든 문구 기록을 Data로 저장할 키

    // 기존 AppConstants.todayQuoteKey와 AppConstants.todayQuoteDateKey 사용
    private let todayQuoteTextKey = AppConstants.todayQuoteKey
    private let todayQuoteDateKey = AppConstants.todayQuoteDateKey

    init() {
        // 앱 실행 시 저장된 모든 문구 기록 로드 (UserDefaults에서)
        loadAllQuotes()

        // 오늘의 문구 로드 (기존 UserDefaults 캐싱 로직 유지)
        if let savedQuoteText = userDefaults.string(forKey: todayQuoteTextKey),
           let savedQuoteDate = userDefaults.object(forKey: todayQuoteDateKey) as? Date {
            let calendar = Calendar.current
            // 오늘 날짜의 문구가 저장되어 있다면 사용하고, allQuotes에도 반영
            if calendar.isDate(savedQuoteDate, inSameDayAs: Date()) {
                self.todayQuote = savedQuoteText
                // Firestore에서 가져올 문구는 id가 Date 스트링이 될 것이므로, 여기서는 UUID로 임시 할당
                // 이 문구는 나중에 Firestore에서 실제 문구를 가져올 때 덮어쓰여질 수 있습니다.
                // Memo와 Emotion은 캐싱된 Quote 객체에서 가져와야 하므로, QuoteService 호출 후 allQuotes 갱신 로직에서 처리하는 것이 더 정확합니다.
                // 여기서는 단순히 todayQuote만 설정하고, fetchAndSaveTodayQuote()에서 Firestore 데이터와 병합/업데이트를 처리합니다.
            } else {
                // 저장된 문구가 오늘 날짜가 아니면 새로 불러오도록 초기화
                self.todayQuote = "새 문구 불러오는 중..."
                fetchAndSaveTodayQuote() // Firebase에서 새 문구 로드 시도
            }
        } else {
            // 저장된 문구가 전혀 없으면 새로 불러오도록 초기화
            self.todayQuote = "첫 문구 로드 중..."
            fetchAndSaveTodayQuote() // Firebase에서 첫 문구 로드 시도
        }
        print("QuoteViewModel 🚀 init: Initializing ViewModel. Final todayQuote: \"\(todayQuote)\"")
    }

    // 모든 문구 기록 로드 (UserDefaults에서)
    func loadAllQuotes() {
        if let savedQuotesData = userDefaults.data(forKey: allQuotesKey) {
            do {
                let decoder = JSONDecoder()
                // Firestore Date (Timestamp)는 Date 타입으로 변환되므로, 기본 디코딩 전략으로 충분합니다.
                allQuotes = try decoder.decode([Quote].self, from: savedQuotesData)
                print("QuoteViewModel 📦 loadAllQuotes: Loaded \(allQuotes.count) quotes from UserDefaults.")
            } catch {
                print("Error decoding all quotes from UserDefaults: \(error.localizedDescription)")
                allQuotes = [] // 오류 발생 시 빈 배열로 초기화
            }
        } else {
            print("QuoteViewModel 📦 loadAllQuotes: No saved quotes found in UserDefaults.")
        }
        
        // 🚨 중요: UserDefaults에 있는 allQuotes와 Firestore의 allQuotes를 동기화해야 합니다.
        // 앱 시작 시 Firestore에서 모든 문구를 가져와 UserDefaults의 데이터와 병합하는 로직을 추가합니다.
        // 이렇게 하면 UserDefaults는 캐시 역할만 하고, 최신 데이터는 Firestore에서 가져옵니다.
        // 그러나, 현재 아키텍처에서는 dailyQuotes 컬렉션에 사용자 메모를 저장하지 않으므로,
        // allQuotes는 사용자 메모를 포함한 "내 문구" 기록을 저장하는 용도로만 사용됩니다.
        // Firestore dailyQuotes는 "원본 문구"를 저장하고, allQuotes는 "사용자별 기록"을 저장하는 개념으로 분리하는 것이 좋습니다.
        // 여기서는 이전에 논의했던 "allQuotes"를 계속 "사용자별 기록"으로 유지한다고 가정합니다.
        // 만약 사용자 메모를 Firestore에 저장하고 싶다면, Firestore 데이터 모델을 확장하고 보안 규칙을 추가해야 합니다.
    }

    // 모든 문구 기록 저장 (UserDefaults에)
    func saveAllQuotes() {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(allQuotes)
            userDefaults.set(encodedData, forKey: allQuotesKey)
            print("QuoteViewModel 💾 saveAllQuotes: Saved \(allQuotes.count) quotes to UserDefaults.")
            // 위젯 업데이트를 트리거할 필요가 있다면 여기서 호출
            // WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error encoding all quotes to UserDefaults: \(error.localizedDescription)")
        }
    }

    // 새로운 문구를 기록에 추가하거나 기존 문구를 업데이트 (UserDefaults 및 Firestore 연동)
    // 이 함수는 이제 Firestore에서 가져온 문구를 기준으로 동작해야 합니다.
    func addOrUpdateQuoteRecord(text: String, date: Date, generatedBy: String?, style: String?) {
        let calendar = Calendar.current
        let todayDocId = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none) // 날짜만 비교

        // allQuotes에서 오늘 날짜의 문구가 있는지 확인
        if let index = allQuotes.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            // 이미 오늘 날짜의 문구가 있다면 텍스트, generatedBy, style만 업데이트
            // 메모와 감정은 그대로 유지 (사용자가 입력한 값)
            allQuotes[index].text = text
            allQuotes[index].generatedBy = generatedBy
            allQuotes[index].style = style
            saveAllQuotes() // 변경사항 저장 (UserDefaults)
            print("QuoteViewModel 📝 addOrUpdateQuoteRecord: Updated quote for date \(todayDocId). New text: \"\(text)\"")
        } else {
            // 없다면 새로운 문구 추가
            // Firebase의 문서 ID (YYYY-MM-DD)를 Quote의 id로 사용
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let firebaseDocId = dateFormatter.string(from: date)

            let newQuote = Quote(id: firebaseDocId, text: text, date: date, memo: nil, emotion: nil, generatedBy: generatedBy, style: style)
            allQuotes.append(newQuote)
            allQuotes.sort(by: { $0.date > $1.date }) // 추가 후 최신 날짜순 정렬
            saveAllQuotes() // 변경사항 저장 (UserDefaults)
            print("QuoteViewModel ✨ addOrUpdateQuoteRecord: Added new quote for date \(todayDocId). Text: \"\(text)\"")
        }
    }

    // 특정 Quote의 메모 및 감정 업데이트 (UserDefaults 및 Firestore 연동)
    func updateQuoteMemoAndEmotion(id: String, memo: String?, emotion: String?) {
        if let index = allQuotes.firstIndex(where: { $0.id == id }) {
            allQuotes[index].memo = memo == "" ? nil : memo // 빈 문자열이면 nil로 저장
            allQuotes[index].emotion = emotion
            
            // ✅ Firestore에도 업데이트 요청 (여기서는 dailyQuotes의 memo/emotion 필드를 업데이트)
            // 주의: Firestore security rules에서 쓰기 권한이 허용되어야 합니다.
            QuoteService.shared.updateQuoteInFirestore(quote: allQuotes[index]) { error in
                if let error = error {
                    print("QuoteViewModel ❌ updateQuoteMemoAndEmotion: Failed to update Firestore: \(error.localizedDescription)")
                    // 사용자에게 오류 알림 등 추가 처리
                } else {
                    print("QuoteViewModel ✅ updateQuoteMemoAndEmotion: Successfully updated memo/emotion in Firestore.")
                    self.saveAllQuotes() // Firestore 업데이트 성공 시 UserDefaults에도 저장
                }
            }
        } else {
            print("QuoteViewModel ⚠️ updateQuoteMemoAndEmotion: Quote with ID \(id) not found.")
        }
    }

    // 오늘의 문구를 Firestore에서 가져와 UserDefaults에 저장하고 allQuotes에 반영
    func fetchAndSaveTodayQuote() {
        QuoteService.shared.fetchTodayQuote { [weak self] fetchedQuoteText in
            guard let self = self else { return }
            print("QuoteViewModel 🌐 fetchAndSaveTodayQuote: Fetched new quote from service: \"\(fetchedQuoteText)\"")
            
            DispatchQueue.main.async {
                self.todayQuote = fetchedQuoteText // 오늘의 문구 UI 업데이트

                // UserDefaults에 오늘의 문구 저장 (캐싱)
                self.userDefaults.set(fetchedQuoteText, forKey: self.todayQuoteTextKey)
                self.userDefaults.set(Date(), forKey: self.todayQuoteDateKey) // 가져온 날짜로 저장

                // fetchedQuoteText는 Firestore의 text 필드만 포함하므로,
                // generateBy, style은 QuoteService.fetchTodayQuote가 Quote 객체를 반환하도록 수정하거나
                // 별도로 가져와야 합니다.
                // 현재는 text만 가져오므로, generatedBy와 style은 nil로 처리합니다.
                // 이 부분을 개선하려면 QuoteService.fetchTodayQuote 함수가 Text 외에 전체 Quote 객체를 반환하도록 수정해야 합니다.
                // 일단은 text만 업데이트하고, generatedBy와 style은 nil로 둡니다.

                self.addOrUpdateQuoteRecord(text: fetchedQuoteText, date: Date(), generatedBy: nil, style: nil)
                
                // Firestore에서 모든 문구를 다시 가져와 allQuotes를 업데이트 (히스토리 화면 동기화)
                // 앱 시작 시 (init) 또는 주기적으로 호출하여 히스토리 데이터의 최신성을 보장할 수 있습니다.
                self.fetchAndLoadAllQuotesFromFirestore()
                
                WidgetCenter.shared.reloadAllTimelines() // 위젯 업데이트
            }
        }
    }
    
    // Firestore에서 모든 문구를 가져와 allQuotes를 업데이트
    func fetchAndLoadAllQuotesFromFirestore() {
        QuoteService.shared.fetchAllQuotes { [weak self] fetchedQuotes in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // Firestore에서 가져온 데이터를 allQuotes에 바로 할당
                // 이 경우, 사용자가 앱에서 수정한 memo나 emotion은 Firestore에 없으므로 덮어쓰여질 수 있습니다.
                // 이 문제를 해결하려면:
                // 1. 사용자 메모/감정을 Firestore의 dailyQuotes 문서에 함께 저장 (권장, 보안 규칙 필요)
                // 2. 아니면 fetchedQuotes와 기존 allQuotes를 병합하는 복잡한 로직 구현
                // 현재는 Firestore dailyQuotes에 메모/감정이 없다고 가정하고 단순하게 덮어씁니다.
                // 만약 사용자가 메모/감정을 저장한 Quote 객체를 유지하려면, 이 로직은 `memo`와 `emotion`을
                // 기존 `allQuotes`에서 찾아 병합해야 합니다.
                
                // Simple merge logic:
                var mergedQuotes = [Quote]()
                for firestoreQuote in fetchedQuotes {
                    // 기존 allQuotes에 같은 id의 문구가 있는지 확인 (메모/감정 보존)
                    if let existingQuoteIndex = self.allQuotes.firstIndex(where: { $0.id == firestoreQuote.id }) {
                        var updatedQuote = firestoreQuote
                        // Firestore에는 없지만, 앱에서 저장된 메모/감정이 있다면 유지
                        updatedQuote.memo = self.allQuotes[existingQuoteIndex].memo
                        updatedQuote.emotion = self.allQuotes[existingQuoteIndex].emotion
                        mergedQuotes.append(updatedQuote)
                    } else {
                        mergedQuotes.append(firestoreQuote)
                    }
                }
                
                self.allQuotes = mergedQuotes.sorted(by: { $0.date > $1.date }) // 최신순 정렬
                self.saveAllQuotes() // 병합된 데이터를 UserDefaults에 저장
                print("QuoteViewModel 🔄 fetchAndLoadAllQuotesFromFirestore: Updated allQuotes with Firestore data. Total \(self.allQuotes.count) quotes.")
            }
        }
    }
}
