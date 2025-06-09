// MARK: - HistoryCalendarView.swift
import SwiftUI

struct HistoryCalendarView: View {
    @EnvironmentObject var settings: UserSettings
    @State private var selectedDate = Date()
    @State private var selectedTag: String? = nil
    @State private var searchText = ""

    let mockQuotes: [Quote] = [
        Quote(id: "1", text: "성공은 작은 노력의 반복이다", date: Date()),
        Quote(id: "2", text: "행복은 선택이다", date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
    ]

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("날짜 선택", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)
                    .colorScheme(settings.preferredColorScheme)

                HStack {
                    TextField("문구 또는 메모 검색", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(settings.fontStyle)

                    Menu {
                        Button("#성공") { selectedTag = "성공" }
                        Button("#행복") { selectedTag = "행복" }
                        Button("모두 보기") { selectedTag = nil }
                    } label: {
                        Label("태그", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                .padding(.horizontal)

                List(filteredQuotes()) { quote in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(quote.text)
                            .font(settings.fontStyle)
                        Text(quote.date, style: .date)
                            .font(.caption)
                    }
                    .padding(8)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("문구 히스토리")
        }
        .preferredColorScheme(settings.preferredColorScheme)
        .toolbarColorScheme(settings.preferredColorScheme, for: .navigationBar)
    }

    func filteredQuotes() -> [Quote] {
        mockQuotes.filter { quote in
            (searchText.isEmpty || quote.text.localizedCaseInsensitiveContains(searchText)) &&
            (selectedTag == nil || quote.text.contains(selectedTag!))
        }
    }
}
