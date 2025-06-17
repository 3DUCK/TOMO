// MARK: - HistoryCalendarView.swift
import SwiftUI
import UIKit

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
        // MARK: - GeometryReader를 최상단에 배치하고 ignoresSafeArea() 적용 (TodayQuoteView와 동일)
        GeometryReader { geometry in
                ZStack {
                    // MARK: - 배경 이미지 레이어: geometry.size를 사용하여 정확한 화면 크기 적용 (TodayQuoteView와 동일)
                    if let bgImage = backgroundImage {
                        Image(uiImage: bgImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height) // GeometryReader가 측정한 정확한 크기
                            .clipped() // 프레임을 벗어나는 부분은 잘라냅니다.
                            .blur(radius: 5)
                            .overlay(
                                Rectangle()
                                    .fill(settings.preferredColorScheme == .dark ?
                                              Color.black.opacity(0.5) :
                                              Color.white.opacity(0.5)
                                          )
                                    .frame(width: geometry.size.width, height: geometry.size.height) // 오버레이도 정확한 크기
                            )
                    } else {
                        Color(.systemBackground)
                            .frame(width: geometry.size.width, height: geometry.size.height) // 배경색도 정확한 크기
                    }

                    // MARK: - 전경 컨텐츠 레이어
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
                                // FSCalendar에서 날짜가 선택될 때마다 필터링을 다시 수행
                                self.selectedStartDate = newStart
                                self.selectedEndDate = newEnd
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
                            // MARK: - TextField 배경 투명, 하단 보더 및 플레이스홀더 색상 변경
                            ZStack(alignment: .leading) { // Placeholder 위치를 위해 ZStack 사용
                                if searchText.isEmpty {
                                    Text("문구 또는 메모 검색")
                                        .foregroundColor(currentColorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7)) // 플레이스홀더 색상
                                        .font(settings.getCustomFont(size: 16))
                                        .padding(.horizontal, 5) // TextField의 기본 패딩과 유사하게 조정
                                }
                                TextField("", text: $searchText) // Placeholder는 별도의 Text 뷰로 처리
                                    .textFieldStyle(PlainTextFieldStyle()) // 기본 스타일 제거
                                    .font(settings.getCustomFont(size: 16))
                                    .foregroundColor(currentColorScheme == .dark ? .white : .black) // 입력 텍스트 색상
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 8)
                                    .background(
                                        // 하단 보더 라인
                                        Rectangle()
                                            .frame(height: 1)
                                            .foregroundColor(currentColorScheme == .dark ? .white : .black)
                                            .padding(.horizontal, 0)
                                            .offset(y: 20) // TextField 아래로 이동 (높이 + 여백 고려)
                                    )
                            }
                            .padding(.bottom, 8) // TextField와 하단 보더 전체의 여백

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
                                // MARK: - 감정 버튼 텍스트 및 아이콘 색상 변경
                                Label("감정", systemImage: "face.smiling")
                                    .font(.body)
                                    .foregroundColor(currentColorScheme == .dark ? .white : .black) // 이 부분을 추가
                            }
                        }
                        .padding(.horizontal)

                        List(filteredQuotes()) { quote in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("\"" + quote.text + "\"")
                                        .font(settings.getCustomFont(size: 20))
                                        .lineSpacing(5)
                                        .foregroundColor(.primary) // Keep primary for text
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
                            .background(
                                Color.clear // 완전히 투명하게 (원래 상태와 같음)
                            )
                            .onTapGesture {
                                selectedQuoteForMemo = quote
                                showingMemoSheet = true
                            }
                        }
                        // MARK: - List의 배경을 투명하게 설정 (TodayQuoteView의 배경과 어우러지도록)
                        .scrollContentBackground(.hidden)
                    }
                }
                .navigationBarHidden(true) // Navigation Bar를 숨깁니다.
                .sheet(item: $selectedQuoteForMemo) { quote in
                    MemoEditView(quote: quote, viewModel: viewModel, isShowingSheet: $showingMemoSheet)
                        .environmentObject(settings)
                }
            }
            // MARK: - GeometryReader 자체가 안전 영역을 무시하도록 설정 (TodayQuoteView와 동일)
            .ignoresSafeArea(.all)
        
        .preferredColorScheme(settings.preferredColorScheme)

        .onAppear {
            viewModel.loadAllQuotes()
            // MARK: - 화면 로드 시 오늘 날짜로 선택 범위 초기화
            let today = Calendar.current.startOfDay(for: Date())
            selectedStartDate = today
            selectedEndDate = today
            
            // FSCalendar의 초기 선택을 반영하기 위해 reloadData 호출 (선택 사항이지만 안전함)
            // FSCalendarRepresentable 내부에서 reloadData()를 didSelect/didDeselect 시 호출하므로
            // 여기서는 굳이 필요 없을 수도 있습니다. 하지만 명시적으로 초기화를 위해 필요하다면 추가할 수 있습니다.
            // 직접 FSCalendar 인스턴스에 접근해야 하므로, Representable의 makeUIView/updateUIView 로직을 수정해야 합니다.
            // 일단은 State 변수만 업데이트해도 filteredQuotes()가 잘 작동하도록 되어 있습니다.
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
                // 날짜가 선택되지 않은 경우 모든 항목을 반환
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
