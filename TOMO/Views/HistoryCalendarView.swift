// MARK: - HistoryCalendarView.swift
import SwiftUI
import UIKit

struct HistoryCalendarView: View {
    @EnvironmentObject var settings: UserSettings
    @StateObject var viewModel = QuoteViewModel()
    
    @State private var selectedStartDate: Date? = nil
    @State private var selectedEndDate: Date? = nil
    @State private var selectedTag: String? = nil
    @State private var searchText = ""
    @State private var selectedQuoteForMemo: Quote? // 메모 편집할 Quote

    let availableTags = ["😊", "😢", "😠", "😎", "😴", "💡", "✨", "🙂"]

    @Environment(\.colorScheme) var currentColorScheme: ColorScheme

    var resolvedAppAccentColor: Color {
        return Color.accentColor
    }
    
    var backgroundImage: UIImage? {
        if let data = settings.backgroundImageData {
            return UIImage(data: data)
        }
        return nil
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let bgImage = backgroundImage {
                    Image(uiImage: bgImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .blur(radius: 5)
                        .overlay(
                            Rectangle()
                                .fill(settings.preferredColorScheme == .dark ?
                                          Color.black.opacity(0.5) :
                                          Color.white.opacity(0.5))
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        )
                } else {
                    Color(.systemBackground)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }

                VStack {
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()

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
                    .frame(height: 300)
                    .padding(.horizontal)

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
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(currentColorScheme == .dark ? .white : .black)
                                        .padding(.horizontal, 0)
                                        .offset(y: 20)
                                )
                        }
                        .padding(.bottom, 8)

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
                                .foregroundColor(currentColorScheme == .dark ? .white : .black)
                        }
                    }
                    .padding(.horizontal)

                    List(filteredQuotes()) { quote in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\"" + quote.text + "\"")
                                    .font(settings.getCustomFont(size: 20))
                                    .lineSpacing(5)
                                    .foregroundColor(.primary)
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
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .cornerRadius(8)
                        .background(Color.clear)
                        .onTapGesture {
                            selectedQuoteForMemo = quote
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedQuoteForMemo) { quote in
                MemoEditView(selectedQuote: $selectedQuoteForMemo, viewModel: viewModel)
                    .environmentObject(settings)
            }
        }
        .ignoresSafeArea(.all)
        .preferredColorScheme(settings.preferredColorScheme)
        .onAppear {
            viewModel.loadAllQuotes()
            let today = Calendar.current.startOfDay(for: Date())
            selectedStartDate = today
            selectedEndDate = today
        }
    }

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

        rangedQuotes = rangedQuotes.filter { quote in
            let textMatches = searchText.isEmpty ||
                              quote.text.localizedCaseInsensitiveContains(searchText) ||
                              (quote.memo?.localizedCaseInsensitiveContains(searchText) ?? false)

            let tagMatches = selectedTag == nil || (quote.emotion == selectedTag)

            return textMatches && tagMatches
        }

        return rangedQuotes.sorted(by: { $0.date > $1.date })
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}
