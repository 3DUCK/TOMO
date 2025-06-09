import WidgetKit
import SwiftUI

struct SimpleEntry: TimelineEntry {
    let date: Date
    let quote: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), quote: "로딩 중...")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), quote: "오늘도 파이팅!")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, quote: "허세 보단 무게.")

        // MARK: - 오류 해결: policy: .atStartOfDay 대신 다음 날 자정으로 설정
        // 다음 날 자정 (새로운 날의 시작)에 위젯을 새로고침하도록 설정합니다.
        guard let nextMidnight = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else {
            // 날짜 계산 실패 시, 일단 지금 시점으로 타임라인을 제공하고 나중에 다시 시도
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
            return
        }
        let startOfNextDay = Calendar.current.startOfDay(for: nextMidnight)

        let timeline = Timeline(entries: [entry], policy: .after(startOfNextDay)) // 다음 날 자정 이후에 업데이트
        
        // 또는 간단히 하루 뒤 업데이트:
        // let nextUpdateDate = currentDate.addingTimeInterval(24 * 60 * 60) // 24시간 후
        // let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))


        completion(timeline)
    }
}

struct TOMOWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Color(.systemBackground)
            Text(entry.quote)
                .padding()
                .multilineTextAlignment(.center)
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
        .configurationDisplayName("오늘의 문구")
        .description("당신에게 매일 동기부여를 드립니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
