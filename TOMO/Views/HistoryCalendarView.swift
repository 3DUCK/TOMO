// MARK: - HistoryCalendarView.swift
import SwiftUI

struct HistoryCalendarView: View {
    @EnvironmentObject var settings: UserSettings
    @StateObject var viewModel = QuoteViewModel() // QuoteViewModel 사용
    
    // MARK: - 날짜 범위 선택을 위한 새로운 State 변수 (FSCalendar와 바인딩)
    @State private var selectedStartDate: Date? = nil
    @State private var selectedEndDate: Date? = nil
    
    @State private var selectedTag: String? = nil
    @State private var searchText = ""
    @State private var showingMemoSheet = false
    @State private var selectedQuoteForMemo: Quote? // 메모 편집할 Quote

    let availableTags = ["😊", "😢", "😠", "😎", "😴", "💡", "✨", "🙂"]
    
    // MARK: - Environment에서 colorScheme 직접 가져오기
    @Environment(\.colorScheme) var currentColorScheme: ColorScheme

    // MARK: - App's accent color (or tint) resolution
    var resolvedAppAccentColor: Color {
        return Color.accentColor // This gets the global accent color set in Asset Catalog or Modifier.
    }
    var backgroundImage: UIImage? {
        if let data = settings.backgroundImageData {
            return UIImage(data: data)
        }
        return nil
    }
    
    var body: some View {
        NavigationView {
            // MARK: - ZStack을 사용하여 배경 이미지와 전경 컨텐츠 분리
            ZStack {
                // 배경 이미지 레이어
                if let bgImage = backgroundImage {
                    Image(uiImage: bgImage)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea() // .all 대신 prefers `ignoresSafeArea()`
                        .blur(radius: 5.0)
                        .overlay(
                            Rectangle()
                                .fill(settings.preferredColorScheme == .dark ?
                                      Color.black.opacity(0.5) :
                                      Color.white.opacity(0.5)
                                     )
                                .ignoresSafeArea() // 오버레이도 전체 화면을 덮도록
                        )
                } else {
                    Color(.systemBackground)
                        .ignoresSafeArea() // 배경색도 전체 화면을 덮도록
                }

                // 전경 컨텐츠 레이어
                VStack {
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    
                    // MARK: - FSCalendarRepresentable 사용
                    FSCalendarRepresentable(
                        selectedStartDate: $selectedStartDate,
                        selectedEndDate: $selectedEndDate,
                        onDatesSelected: { newStart, newEnd in
                            print("FSCalendar: Dates selected: \(newStart?.formatted() ?? "nil") ~ \(newEnd?.formatted() ?? "nil")")
                        },
                        calendarAccentColor: resolvedAppAccentColor, // 이제 확실한 Color 타입 전달
                        isDarkMode: currentColorScheme == .dark // 현재 다크모드 여부 전달
                    )
                    .frame(height: 300) // 캘린더의 높이 설정 (FSCalendar는 고정 높이가 필요)
                    .padding(.horizontal)
                    
                    // MARK: - 선택된 날짜 범위 표시
                    if let start = selectedStartDate, let end = selectedEndDate {
                        Text("선택된 기간: \(start, formatter: dateFormatter) ~ \(end, formatter: dateFormatter)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else if let start = selectedStartDate {
                        Text("시작일: \(start, formatter: dateFormatter) (마침일 선택 대기 중)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        Text("시작일과 마침일을 선택해주세요.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }

                    HStack {
                        TextField("문구 또는 메모 검색", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(settings.getCustomFont(size: 16))

                        Menu {
                            ForEach(availableTags, id: \.self) { tag in
                                Button(action: {
                                    selectedTag = tag
                                }) {
                                    Text(tag)
                                }
                            }
                            Button("모두 보기") { selectedTag = nil }
                        } label: {
                            Label("감정", systemImage: "face.smiling")
                                .font(.body)
                        }
                    }
                    .padding(.horizontal)

                    List(filteredQuotes()) { quote in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\"" + quote.text + "\"")
                                    .font(settings.getCustomFont(size: 20))
                                    .lineSpacing(5)
                                    .foregroundColor(isDateInSelectedRange(quote.date) ? .primary : .primary) // Keep primary for text
                                Spacer()
                                if let emotion = quote.emotion, !emotion.isEmpty {
                                    Text(emotion)
                                        .font(.title3)
                                }
                            }
                            
                            if let memo = quote.memo, !memo.isEmpty {
                                Text(memo)
                                    .font(settings.getCustomFont(size: 14))
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }
                            
                            Text(quote.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary) // Keep secondary for date text
                        }
                        .padding(8)
                        .cornerRadius(8) // Optional: Add corner radius for better visual
                        .onTapGesture {
                            selectedQuoteForMemo = quote
                            showingMemoSheet = true
                        }
                    }
                    .scrollContentBackground(.hidden) // List의 배경을 투명하게 만듦
                }
            }
            .sheet(item: $selectedQuoteForMemo) { quote in
                MemoEditView(quote: quote, viewModel: viewModel, isShowingSheet: $showingMemoSheet)
                    .environmentObject(settings)
            }
        }
        .preferredColorScheme(settings.preferredColorScheme)
        .toolbarColorScheme(settings.preferredColorScheme, for: .navigationBar)
        .onAppear {
            viewModel.loadAllQuotes()
            // 앱 로드 시 FSCalendar 초기 선택 설정 (선택 사항)
            // 예를 들어, 오늘 날짜를 시작일로 자동 선택하려면:
            // selectedStartDate = Calendar.current.startOfDay(for: Date())
        }
    }

    // MARK: - 날짜가 선택된 범위 내에 있는지 확인하는 헬퍼 함수
    private func isDateInSelectedRange(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)

        if let start = selectedStartDate, let end = selectedEndDate {
            let startOfRange = calendar.startOfDay(for: start)
            let endOfRange = calendar.startOfDay(for: end)
            return targetDay >= startOfRange && targetDay <= endOfRange
        } else if let start = selectedStartDate {
            let startOfRange = calendar.startOfDay(for: start)
            return targetDay == startOfRange
        }
        return false
    }

    // MARK: - 필터링 로직 (FSCalendar의 선택 상태를 따름)
    func filteredQuotes() -> [Quote] {
        let calendar = Calendar.current
        
        var rangedQuotes = viewModel.allQuotes.filter { quote in
            let quoteDay = calendar.startOfDay(for: quote.date)
            
            if let start = selectedStartDate, let end = selectedEndDate {
                return quoteDay >= calendar.startOfDay(for: start) &&
                        quoteDay <= calendar.startOfDay(for: end)
            } else if let start = selectedStartDate {
                return quoteDay == calendar.startOfDay(for: start)
            } else {
                return true
            }
        }
        
        // 2. 검색어와 태그로 추가 필터링
        rangedQuotes = rangedQuotes.filter { quote in
            let textMatches = searchText.isEmpty ||
                                 quote.text.localizedCaseInsensitiveContains(searchText) ||
                                 (quote.memo?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let tagMatches = selectedTag == nil || (quote.emotion == selectedTag)
                                  
            return textMatches && tagMatches
        }
        
        // 날짜 범위 선택 시 최신순으로 정렬
        return rangedQuotes.sorted(by: { $0.date > $1.date })
    }
    
    // 날짜 포맷터
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}
