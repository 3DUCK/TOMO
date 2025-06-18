//
// HistoryCalendarView.swift
//
// 이 파일은 앱의 '기록' 탭에 해당하는 뷰를 정의합니다.
// 사용자가 과거의 문구 기록들을 날짜, 감정 태그, 검색어를 기반으로 조회하고
// 관리할 수 있도록 캘린더(`FSCalendarRepresentable`)와 목록(`List`)을 제공합니다.
//
// 주요 기능:
// - 사용자 설정(폰트, 배경 이미지, 테마 등)을 `UserSettings`를 통해 적용합니다.
// - `QuoteViewModel`을 사용하여 문구 데이터를 가져오고 필터링합니다.
// - 특정 날짜 범위, 감정 태그, 텍스트 검색을 통해 문구 기록을 필터링합니다.
// - 각 문구에 대한 메모와 감정을 편집할 수 있는 시트(`MemoEditView`)를 제공합니다.
// - 사용자 지정 폰트 및 배경 이미지 설정을 UI에 반영합니다.
//

import SwiftUI
import UIKit // UIImage를 사용하기 위해 임포트

/// 사용자의 문구 기록을 캘린더와 목록 형태로 보여주는 SwiftUI 뷰.
/// 날짜, 감정 태그, 검색어 필터링 기능을 제공하며, 메모 편집을 지원합니다.
struct HistoryCalendarView: View {
    /// 사용자 설정(폰트, 테마, 배경 이미지 등)을 관리하는 환경 객체.
    @EnvironmentObject var settings: UserSettings
    /// 문구 데이터와 로직을 관리하는 상태 객체.
    @StateObject var viewModel = QuoteViewModel()
    
    // MARK: - State Properties

    /// 캘린더에서 선택된 시작 날짜.
    @State private var selectedStartDate: Date? = nil
    /// 캘린더에서 선택된 끝 날짜.
    @State private var selectedEndDate: Date? = nil
    /// 현재 선택된 감정 태그 필터.
    @State private var selectedTag: String? = nil
    /// 문구 또는 메모 검색을 위한 텍스트.
    @State private var searchText = ""
    /// 메모를 편집하기 위해 선택된 `Quote` 객체.
    @State private var selectedQuoteForMemo: Quote?

    /// 사용 가능한 감정 태그 목록.
    let availableTags = ["😊", "😢", "😠", "😎", "😴", "💡", "✨", "🙂"]

    /// 현재 시스템의 다크/라이트 모드 설정.
    @Environment(\.colorScheme) var currentColorScheme: ColorScheme

    // MARK: - Computed Properties

    /// 앱의 현재 AccentColor를 반환합니다.
    var resolvedAppAccentColor: Color {
        return Color.accentColor
    }
    
    /// `UserSettings`에 저장된 배경 이미지 데이터를 `UIImage`로 변환하여 반환합니다.
    /// 이미지가 없으면 `nil`을 반환합니다.
    var backgroundImage: UIImage? {
        if let data = settings.backgroundImageData {
            return UIImage(data: data)
        }
        return nil
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 배경 이미지 또는 기본 배경색 설정
                if let bgImage = backgroundImage {
                    Image(uiImage: bgImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .blur(radius: 5) // 배경 이미지에 블러 효과 적용
                        .overlay(
                            // 테마에 따라 오버레이 색상 및 투명도 조절
                            Rectangle()
                                .fill(settings.preferredColorScheme == .dark ?
                                      Color.black.opacity(0.5) : // 다크 모드일 때 어둡게
                                      Color.white.opacity(0.5))   // 라이트 모드일 때 밝게
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        )
                } else {
                    // 배경 이미지가 없을 경우 시스템 배경색 사용
                    Color(.systemBackground)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }

                VStack {
                    // 상단에 여백을 주어 캘린더와 목록이 적절한 위치에 오도록 조정
                    Spacer() // Spacer()를 여러 개 사용하여 상단 여백 조절
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()

                    // 캘린더 UI (FSCalendar를 SwiftUI에서 사용하기 위한 Representable)
                    FSCalendarRepresentable(
                        selectedStartDate: $selectedStartDate,
                        selectedEndDate: $selectedEndDate,
                        onDatesSelected: { newStart, newEnd in
                            print("FSCalendar: Dates selected: \(newStart?.formatted() ?? "nil") ~ \(newEnd?.formatted() ?? "nil")")
                            self.selectedStartDate = newStart
                            self.selectedEndDate = newEnd
                        },
                        calendarAccentColor: resolvedAppAccentColor,
                        isDarkMode: currentColorScheme == .dark
                    )
                    .frame(height: 300) // 캘린더 높이 고정
                    .padding(.horizontal) // 좌우 패딩

                    // 선택된 날짜 범위 표시 텍스트
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

                    // 검색 바 및 감정 태그 필터 메뉴
                    HStack {
                        ZStack(alignment: .leading) {
                            if searchText.isEmpty {
                                Text("문구 또는 메모 검색")
                                    .foregroundColor(currentColorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                                    .font(settings.getCustomFont(size: 16))
                                    .padding(.horizontal, 5)
                            }
                            TextField("", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(settings.getCustomFont(size: 16))
                                .foregroundColor(currentColorScheme == .dark ? .white : .black)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 8)
                                .background(
                                    // 검색 필드 하단에 구분선 추가
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(currentColorScheme == .dark ? .white : .black)
                                        .padding(.horizontal, 0)
                                        .offset(y: 20) // 텍스트 필드 아래로 이동
                                )
                        }
                        .padding(.bottom, 8) // 검색 필드와 다음 요소 간 간격

                        // 감정 태그 선택 메뉴
                        Menu {
                            ForEach(availableTags, id: \.self) { tag in
                                Button(action: {
                                    selectedTag = tag // 태그 선택
                                }) {
                                    Text(tag)
                                }
                            }
                            Button("모두 보기") { selectedTag = nil } // 필터 초기화
                        } label: {
                            Label(selectedTag ?? "감정", systemImage: "face.smiling") // 선택된 태그 표시 또는 기본 "감정"
                                .font(.body)
                                .foregroundColor(currentColorScheme == .dark ? .white : .black)
                        }
                    }
                    .padding(.horizontal) // 검색 바 및 메뉴의 좌우 패딩

                    // 필터링된 문구 목록
                    List(filteredQuotes()) { quote in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                // 현재 사용자 목표에 맞는 문구 텍스트를 표시
                                Text("\"" + getQuoteText(for: quote) + "\"")
                                    .font(settings.getCustomFont(size: 20))
                                    .lineSpacing(5) // 줄 간격
                                    .foregroundColor(.primary) // 기본 전경색
                                Spacer()
                                // 감정 태그가 있다면 표시
                                if let emotion = quote.emotion, !emotion.isEmpty {
                                    Text(emotion)
                                        .font(.title3)
                                }
                            }

                            // 메모가 있다면 표시
                            if let memo = quote.memo, !memo.isEmpty {
                                Text(memo)
                                    .font(settings.getCustomFont(size: 14))
                                    .foregroundColor(.gray)
                                    .lineLimit(2) // 두 줄까지만 표시
                            }

                            // 문구 생성 날짜 표시
                            Text(quote.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .cornerRadius(8) // 모서리 둥글게 (배경이 투명해도 시각적 구분)
                        .background(Color.clear) // List 배경에 영향을 받지 않도록 투명 설정
                        .onTapGesture {
                            selectedQuoteForMemo = quote // 탭 시 메모 편집 시트 표시
                        }
                    }
                    .scrollContentBackground(.hidden) // iOS 16+ 리스트 배경 숨기기
                }
            }
            .navigationBarHidden(true) // 네비게이션 바 숨기기
            // 메모 편집 시트
            .sheet(item: $selectedQuoteForMemo) { quote in
                MemoEditView(selectedQuote: $selectedQuoteForMemo, viewModel: viewModel)
                    .environmentObject(settings) // UserSettings 환경 객체 전달
            }
        }
        .ignoresSafeArea(.all) // 모든 SafeArea 무시 (배경 이미지가 전체 화면을 덮도록)
        .preferredColorScheme(settings.preferredColorScheme) // 사용자 설정에 따른 다크/라이트 모드 적용
        .onAppear {
            // 뷰가 나타날 때 모든 문구 기록을 로드하고, 기본적으로 오늘 날짜를 선택
            viewModel.loadAllQuotes()
            let today = Calendar.current.startOfDay(for: Date())
            selectedStartDate = today
            selectedEndDate = today
            print("HistoryCalendarView ➡️ onAppear: Initialized selected dates to today.")
        }
    }

    // MARK: - Helper Functions

    /// 주어진 날짜가 선택된 기간(selectedStartDate ~ selectedEndDate) 내에 있는지 확인합니다.
    /// (현재는 `FSCalendarRepresentable`에서 날짜 선택 로직을 처리하므로 이 함수는 직접 사용되지 않을 수 있습니다.)
    /// - Parameter date: 확인할 날짜.
    /// - Returns: 날짜가 선택된 기간 내에 있으면 `true`, 그렇지 않으면 `false`.
    private func isDateInSelectedRange(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date) // 시간 정보를 제거하고 날짜만 비교

        if let start = selectedStartDate, let end = selectedEndDate {
            let startOfRange = calendar.startOfDay(for: start)
            let endOfRange = calendar.startOfDay(for: end)
            return targetDay >= startOfRange && targetDay <= endOfRange
        } else if let start = selectedStartDate {
            let startOfRange = calendar.startOfDay(for: start)
            return targetDay == startOfRange // 시작일만 선택된 경우 해당 날짜만
        }
        return false // 아무 날짜도 선택되지 않은 경우
    }

    /// 현재 필터링 조건(날짜 범위, 검색어, 감정 태그)에 따라 문구 목록을 필터링하고 정렬하여 반환합니다.
    /// - Returns: 필터링되고 정렬된 `[Quote]` 배열.
    func filteredQuotes() -> [Quote] {
        let calendar = Calendar.current

        // 1. 날짜 범위 필터링
        var rangedQuotes = viewModel.allQuotes.filter { quote in
            let quoteDay = calendar.startOfDay(for: quote.date) // 문구의 날짜를 시간 없이 비교
            if let start = selectedStartDate, let end = selectedEndDate {
                // 시작일과 종료일 모두 선택된 경우
                let startOfRange = calendar.startOfDay(for: start)
                let endOfRange = calendar.startOfDay(for: end)
                return quoteDay >= startOfRange && quoteDay <= endOfRange
            } else if let start = selectedStartDate {
                // 시작일만 선택된 경우 (단일 날짜 선택)
                return quoteDay == calendar.startOfDay(for: start)
            } else {
                return true // 날짜 필터가 없으면 모든 문구 포함
            }
        }

        // 2. goal, 검색어, 감정 태그 필터링
        rangedQuotes = rangedQuotes.filter { quote in
            // 사용자 목표(settings.goal)와 문구의 goal 필드가 일치하거나, 문구의 goal 필드가 없는 경우
            let goalMatches = (quote.goal == nil) || (quote.goal == settings.goal)
            
            // 검색어가 비어있거나, 문구 텍스트 또는 메모에 검색어가 포함되는 경우 (대소문자 무시)
            let textMatches = searchText.isEmpty ||
                getQuoteText(for: quote).localizedCaseInsensitiveContains(searchText) ||
                (quote.memo?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            // 선택된 태그가 없거나, 문구의 감정 태그가 선택된 태그와 일치하는 경우
            let tagMatches = selectedTag == nil || (quote.emotion == selectedTag)
            
            return goalMatches && textMatches && tagMatches
        }

        // 3. 최신 날짜순으로 정렬
        return rangedQuotes.sorted(by: { $0.date > $1.date })
    }

    /// 사용자의 현재 `goal` 설정에 따라 `Quote` 객체에서 해당하는 문구 텍스트를 반환합니다.
    /// - Parameter quote: 텍스트를 가져올 `Quote` 객체.
    /// - Returns: 사용자의 목표에 해당하는 문구 텍스트, 또는 빈 문자열.
    private func getQuoteText(for quote: Quote) -> String {
        switch settings.goal {
        case "취업":
            return quote.employment ?? ""
        case "다이어트":
            return quote.diet ?? ""
        case "자기계발":
            return quote.selfdev ?? ""
        case "학업":
            return quote.study ?? ""
        default:
            return "" // 일치하는 목표가 없거나 기본값
        }
    }

    /// 날짜를 짧은 형식으로 포맷팅하는 `DateFormatter` 인스턴스.
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // 예: "2024년 6월 18일"
        formatter.timeStyle = .none   // 시간 정보는 표시하지 않음
        return formatter
    }
}
