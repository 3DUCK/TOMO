//
// QuoteViewModel.swift
//
// 이 파일은 앱의 핵심 비즈니스 로직과 데이터 관리를 담당하는 ViewModel 클래스입니다.
// 사용자에게 보여질 '오늘의 문구' 및 '모든 문구 기록' 데이터를 관리하며,
// UI(View)와 서비스 계층(QuoteService, UserDefaults) 사이의 중재자 역할을 수행합니다.
//
// 주요 기능:
// - @Published 프로퍼티를 통해 뷰에 실시간으로 데이터 변경 사항을 알립니다.
// - UserDefaults를 사용하여 앱 그룹에 사용자별 문구 기록(allQuotes) 및 오늘의 문구를 캐싱하고 관리합니다.
// - QuoteService를 통해 Firebase Firestore에서 문구를 비동기적으로 가져오고 업데이트합니다.
// - 위젯과 앱 간의 데이터 동기화를 위해 WidgetCenter를 사용하여 위젯 타임라인을 새로고침합니다.
// - 사용자 메모 및 감정 업데이트 로직을 포함하여, 기록된 문구에 대한 사용자 상호작용을 처리합니다.
//

import Foundation
import Combine // @Published와 같은 Combine 프레임워크 기능 사용
import WidgetKit // WidgetCenter를 사용하여 위젯 업데이트

/// 앱의 문구 관련 데이터를 관리하고 UI에 제공하는 ViewModel 클래스.
/// `ObservableObject`를 채택하여 SwiftUI 뷰에서 데이터 변경 사항을 관찰할 수 있도록 합니다.
class QuoteViewModel: ObservableObject {
    /// 사용자에게 보여질 오늘의 문구. 변경 시 UI가 업데이트됩니다.
    @Published var todayQuote: String = "불러오는 중..."
    /// 앱에 저장된 모든 문구 기록. 변경 시 UI가 업데이트됩니다.
    @Published var allQuotes: [Quote] = []

    /// 앱 그룹 UserDefaults 인스턴스. 앱과 위젯 간의 데이터 공유에 사용됩니다.
    private let userDefaults = UserDefaults(suiteName: AppConstants.appGroupID)!
    /// 모든 문구 기록을 Data 형태로 UserDefaults에 저장할 때 사용되는 키.
    private let allQuotesKey = "allQuotesData"

    /// 오늘의 문구 텍스트를 UserDefaults에 저장하는 키 (AppConstants 참조).
    private let todayQuoteTextKey = AppConstants.todayQuoteKey
    /// 오늘의 문구가 생성된 날짜를 UserDefaults에 저장하는 키 (AppConstants 참조).
    private let todayQuoteDateKey = AppConstants.todayQuoteDateKey

    // MARK: - Initialization

    /// `QuoteViewModel` 초기화 메서드.
    /// 앱 시작 시 저장된 모든 문구 기록과 오늘의 문구를 로드합니다.
    /// 오늘의 문구가 오늘 날짜가 아니면 Firestore에서 새 문구를 가져옵니다.
    init() {
        // 앱 실행 시 저장된 모든 문구 기록 로드
        loadAllQuotes()

        // 오늘의 문구 로드 (UserDefaults 캐싱 로직 유지)
        if let savedQuoteText = userDefaults.string(forKey: todayQuoteTextKey),
           let savedQuoteDate = userDefaults.object(forKey: todayQuoteDateKey) as? Date {
            let calendar = Calendar.current
            
            // 저장된 문구가 오늘 날짜의 문구인지 확인
            if calendar.isDate(savedQuoteDate, inSameDayAs: Date()) {
                self.todayQuote = savedQuoteText
                print("QuoteViewModel 🚀 init: Cached today's quote found for \(DateFormatter.localizedString(from: savedQuoteDate, dateStyle: .short, timeStyle: .none)).")
            } else {
                // 저장된 문구가 오늘 날짜가 아니면 새로 불러오도록 설정
                self.todayQuote = "새 문구 불러오는 중..."
                let savedGoal = userDefaults.string(forKey: "goal") ?? "취업" // UserSettings에서 goal 가져오기
                print("QuoteViewModel 🚀 init: Cached quote is outdated. Fetching new quote for goal: \(savedGoal).")
                fetchAndSaveTodayQuote(goal: savedGoal) // Firebase에서 새 문구 로드 시도
            }
        } else {
            // 저장된 문구가 전혀 없으면 새로 불러오도록 설정
            self.todayQuote = "첫 문구 로드 중..."
            let savedGoal = userDefaults.string(forKey: "goal") ?? "취업" // UserSettings에서 goal 가져오기
            print("QuoteViewModel 🚀 init: No cached quote found. Fetching initial quote for goal: \(savedGoal).")
            fetchAndSaveTodayQuote(goal: savedGoal) // Firebase에서 첫 문구 로드 시도
        }
        
        // 모든 문구 기록은 `init` 시점에 `loadAllQuotes()`로 불러오고,
        // 나중에 `fetchAndLoadAllQuotesFromFirestore()`를 통해 Firestore와 동기화합니다.
        // 이는 Firestore의 원본 데이터와 사용자가 추가한 메모/감정을 병합하기 위함입니다.
        print("QuoteViewModel 🚀 init: ViewModel initialized. Current todayQuote: \"\(todayQuote)\"")
    }

    // MARK: - Local Data Management (UserDefaults)

    /// UserDefaults에서 모든 문구 기록을 로드합니다.
    /// 저장된 `Data`를 `[Quote]` 배열로 디코딩합니다.
    func loadAllQuotes() {
        if let savedQuotesData = userDefaults.data(forKey: allQuotesKey) {
            do {
                let decoder = JSONDecoder()
                allQuotes = try decoder.decode([Quote].self, from: savedQuotesData)
                print("QuoteViewModel 📦 loadAllQuotes: Successfully loaded \(allQuotes.count) quotes from UserDefaults.")
            } catch {
                print("QuoteViewModel ❌ loadAllQuotes: Error decoding all quotes from UserDefaults: \(error.localizedDescription)")
                allQuotes = [] // 디코딩 오류 발생 시 빈 배열로 초기화
            }
        } else {
            print("QuoteViewModel 📦 loadAllQuotes: No saved quotes data found in UserDefaults.")
        }
    }

    /// 모든 문구 기록을 UserDefaults에 저장합니다.
    /// `[Quote]` 배열을 `Data` 형태로 인코딩하여 저장합니다.
    func saveAllQuotes() {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(allQuotes)
            userDefaults.set(encodedData, forKey: allQuotesKey)
            print("QuoteViewModel 💾 saveAllQuotes: Successfully saved \(allQuotes.count) quotes to UserDefaults.")
            // 모든 문구 기록 저장 시 위젯 업데이트를 트리거할 필요는 일반적으로 없지만,
            // 만약 위젯이 '모든 문구 기록'을 직접 사용한다면 여기서 호출할 수 있습니다.
            // WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("QuoteViewModel ❌ saveAllQuotes: Error encoding all quotes to UserDefaults: \(error.localizedDescription)")
        }
    }

    // MARK: - Quote Record Management

    /// 새로운 문구 기록을 추가하거나 기존 문구 기록을 업데이트합니다.
    /// 날짜가 같은 문구가 이미 존재하면 해당 문구의 텍스트, 생성 주체, 스타일, 목표만 업데이트합니다.
    /// - Parameters:
    ///   - text: 문구 내용.
    ///   - date: 문구가 생성된 날짜.
    ///   - generatedBy: 문구 생성 주체 (예: "OpenAI", "Gemini", nil).
    ///   - style: 문구 스타일 (예: "감성적", "실용적", nil).
    ///   - goal: 문구의 목표 주제 (예: "취업", "다이어트", nil).
    func addOrUpdateQuoteRecord(text: String, date: Date, generatedBy: String?, style: String?, goal: String?) {
        let calendar = Calendar.current
        let todayDocId = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)

        // allQuotes 배열에서 오늘 날짜와 동일한 문구가 있는지 확인
        if let index = allQuotes.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            // 이미 오늘 날짜의 문구가 있다면 텍스트, generatedBy, style, goal만 업데이트
            allQuotes[index].text = text
            allQuotes[index].generatedBy = generatedBy
            allQuotes[index].style = style
            allQuotes[index].goal = goal
            saveAllQuotes() // 변경사항 UserDefaults에 저장
            print("QuoteViewModel 📝 addOrUpdateQuoteRecord: Updated existing quote for date \(todayDocId). New text: \"\(text)\"")
        } else {
            // 오늘 날짜의 문구가 없다면 새로운 Quote 객체를 생성하여 추가
            // Firestore 문서 ID와 일치하도록 'yyyy-MM-dd' 형식의 ID 사용
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let firebaseDocId = dateFormatter.string(from: date)

            let newQuote = Quote(id: firebaseDocId, text: text, date: date, memo: nil, emotion: nil, generatedBy: generatedBy, style: style, goal: goal)
            allQuotes.append(newQuote)
            allQuotes.sort(by: { $0.date > $1.date }) // 최신 날짜순으로 정렬
            saveAllQuotes() // 변경사항 UserDefaults에 저장
            print("QuoteViewModel ✨ addOrUpdateQuoteRecord: Added new quote record for date \(todayDocId). Text: \"\(text)\"")
        }
    }

    /// 특정 문구 기록의 메모와 감정을 업데이트하고, 이를 UserDefaults와 Firestore에 반영합니다.
    /// - Parameters:
    ///   - id: 업데이트할 문구의 고유 ID.
    ///   - memo: 새로운 메모 내용 (nil 또는 빈 문자열은 메모 없음으로 처리).
    ///   - emotion: 새로운 감정 이모티콘 (nil 허용).
    func updateQuoteMemoAndEmotion(id: String, memo: String?, emotion: String?) {
        // allQuotes 배열에서 해당 ID의 문구를 찾아 업데이트
        if let index = allQuotes.firstIndex(where: { $0.id == id }) {
            allQuotes[index].memo = memo == "" ? nil : memo // 빈 문자열이면 nil로 변환하여 저장
            allQuotes[index].emotion = emotion
            
            // 업데이트된 Quote 객체를 Firestore에 동기화 요청
            QuoteService.shared.updateQuoteInFirestore(quote: allQuotes[index]) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    print("QuoteViewModel ❌ updateQuoteMemoAndEmotion: Failed to update memo/emotion in Firestore for ID \(id): \(error.localizedDescription)")
                    // 사용자에게 오류 메시지를 표시하는 등의 추가 처리가 필요할 수 있습니다.
                } else {
                    print("QuoteViewModel ✅ updateQuoteMemoAndEmotion: Successfully updated memo/emotion in Firestore for ID \(id).")
                    self.saveAllQuotes() // Firestore 업데이트 성공 시, 로컬 UserDefaults에도 저장
                }
            }
        } else {
            print("QuoteViewModel ⚠️ updateQuoteMemoAndEmotion: Quote with ID \(id) not found in allQuotes.")
        }
    }

    // MARK: - Data Synchronization (Firestore)

    /// Firebase Firestore에서 오늘의 문구를 가져와 UserDefaults에 저장하고, `todayQuote`를 업데이트합니다.
    /// 또한, `allQuotes` 기록에도 해당 문구를 반영하고, 위젯을 새로고침합니다.
    /// - Parameter goal: 사용자 설정 목표 (예: "취업", "다이어트")에 따라 문구를 가져옵니다.
    func fetchAndSaveTodayQuote(goal: String) {
        QuoteService.shared.fetchTodayQuote(forGoal: goal) { [weak self] fetchedQuoteText in
            guard let self = self else { return }
            // UI 업데이트는 메인 스레드에서 진행
            DispatchQueue.main.async {
                self.todayQuote = fetchedQuoteText // 오늘의 문구 업데이트
                self.userDefaults.set(fetchedQuoteText, forKey: self.todayQuoteTextKey) // UserDefaults에 오늘의 문구 저장
                self.userDefaults.set(Date(), forKey: self.todayQuoteDateKey) // 오늘의 문구 저장 날짜 업데이트
                
                // 오늘 문구 기록을 allQuotes에 추가 또는 업데이트
                // Firestore의 dailyQuotes는 memo/emotion 필드를 포함하지 않는다고 가정하고 nil로 전달
                self.addOrUpdateQuoteRecord(text: fetchedQuoteText, date: Date(), generatedBy: nil, style: nil, goal: goal)
                
                // 최신 Firestore 데이터를 기반으로 모든 문구 기록을 다시 로드 (memo/emotion 병합 포함)
                self.fetchAndLoadAllQuotesFromFirestore()
                
                // 위젯에 최신 문구가 반영되도록 위젯 타임라인 새로고침
                WidgetCenter.shared.reloadAllTimelines()
                print("QuoteViewModel 🔄 fetchAndSaveTodayQuote: Fetched and saved new todayQuote: \"\(fetchedQuoteText)\". Widgets reloaded.")
            }
        }
    }
    
    /// Firebase Firestore에서 모든 문구 기록을 가져와 `allQuotes`를 업데이트합니다.
    /// 기존 로컬 `allQuotes`에 있는 사용자 메모 및 감정 정보는 Firestore 데이터와 병합하여 유지합니다.
    func fetchAndLoadAllQuotesFromFirestore() {
        QuoteService.shared.fetchAllQuotes { [weak self] fetchedQuotes in
            guard let self = self else { return }
            DispatchQueue.main.async {
                var mergedQuotes = [Quote]()
                
                // Firestore에서 가져온 각 문구에 대해 처리
                for firestoreQuote in fetchedQuotes {
                    // 기존 `allQuotes`에 동일한 ID의 문구가 있는지 찾아 사용자 메모/감정 정보를 보존
                    if let existingQuoteIndex = self.allQuotes.firstIndex(where: { $0.id == firestoreQuote.id }) {
                        var updatedQuote = firestoreQuote
                        // Firestore에는 없지만 로컬에 저장된 메모와 감정이 있다면 `updatedQuote`에 반영
                        updatedQuote.memo = self.allQuotes[existingQuoteIndex].memo
                        updatedQuote.emotion = self.allQuotes[existingQuoteIndex].emotion
                        mergedQuotes.append(updatedQuote)
                    } else {
                        // 기존 `allQuotes`에 없는 새로운 문구는 그대로 추가
                        mergedQuotes.append(firestoreQuote)
                    }
                }
                
                // 병합된 문구 목록을 날짜 기준(최신순)으로 정렬하여 `allQuotes`에 할당
                self.allQuotes = mergedQuotes.sorted(by: { $0.date > $1.date })
                self.saveAllQuotes() // 병합된 최신 데이터를 UserDefaults에 저장
                print("QuoteViewModel 🔄 fetchAndLoadAllQuotesFromFirestore: Successfully merged and updated allQuotes with Firestore data. Total \(self.allQuotes.count) quotes.")
            }
        }
    }
}
