// MARK: - TOMOWidget.swift
import WidgetKit
import SwiftUI

// AppConstants는 위젯 타겟에도 추가되어 있어야 합니다! (이전 답변 참조)

struct SimpleEntry: TimelineEntry {
    let date: Date
    let quote: String
    let fontSetting: String // 추가: 폰트 설정을 저장할 속성
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        // placeholder에서는 기본 폰트 설정을 사용하거나, 위젯 로드 전이므로 명확하게 설정할 필요가 없습니다.
        SimpleEntry(date: Date(), quote: "로딩 중...", fontSetting: "고양일산 L") // 기본값
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let quote = loadQuote()
        let fontSetting = loadFontSetting() // 폰트 설정 로드
        completion(SimpleEntry(date: Date(), quote: quote, fontSetting: fontSetting))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let quote = loadQuote()
        let fontSetting = loadFontSetting() // 폰트 설정 로드
        let entry = SimpleEntry(date: Date(), quote: quote, fontSetting: fontSetting)

        // 위젯 업데이트 정책: 하루에 한 번 업데이트하도록 설정
        // .atEnd 대신 다음 날 자정으로 설정하는 것이 일반적
        let currentDate = Date()
        guard let nextMidnight = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else {
            // 날짜 계산 실패 시, 일단 지금 시점으로 타임라인을 제공하고 나중에 다시 시도
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
            return
        }
        let startOfNextDay = Calendar.current.startOfDay(for: nextMidnight)

        let timeline = Timeline(entries: [entry], policy: .after(startOfNextDay)) // 다음 날 자정 이후에 업데이트

        completion(timeline)
    }

    func loadQuote() -> String {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        return defaults?.string(forKey: AppConstants.todayQuoteKey) ?? "위젯 문구 없음"
    }

    // 추가: 폰트 설정을 앱 그룹 UserDefaults에서 로드하는 함수
    func loadFontSetting() -> String {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        return defaults?.string(forKey: "font") ?? "고양일산 L" // UserSettings에서 사용한 키 "font"와 동일하게
    }
}

struct TOMOWidgetEntryView : View {
    var entry: Provider.Entry

    // 위젯에서 사용할 폰트 스타일을 결정하는 연산 프로퍼티
    var widgetFontStyle: Font {
        if entry.fontSetting == "고양일산 L" {
            // 여기에 실제 폰트 이름 또는 시스템 폰트 스타일을 사용
            // 예: Font.custom("GoyangilsanL", size: 17)
            return Font.custom("Goyangilsan L", size: 20)
        } else if entry.fontSetting == "고양일산 R" {
            // 여기에 실제 폰트 이름 또는 시스템 폰트 스타일을 사용
            // 예: Font.custom("Batang", size: 17)
            return Font.custom("Goyangilsan R", size: 20) // 예시
        } else {
            return .body
        }
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
            Text(entry.quote)
                .multilineTextAlignment(.center)
                .padding()
                .font(widgetFontStyle) // 위젯 폰트 스타일 적용
        }
    }
}

@main
struct TOMOWidget: Widget {
    let kind: String = "TOMOWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TOMOWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("TOMO 위젯")
        .description("오늘의 문구를 보여줍니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
