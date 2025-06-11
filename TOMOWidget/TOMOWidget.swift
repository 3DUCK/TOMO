// MARK: - TOMOWidget.swift
import WidgetKit
import SwiftUI
import UIKit // UIImage를 사용하기 위해 필요

// AppConstants는 위젯 타겟에도 추가되어 있어야 합니다! (이전 답변 참조)

struct SimpleEntry: TimelineEntry {
    let date: Date
    let quote: String
    let fontSetting: String // 추가: 폰트 설정을 저장할 속성
    let backgroundImageData: Data? // 추가: 배경 이미지 데이터를 저장할 속성
    let currentTheme: String // 추가: 현재 테마를 저장할 속성 (밝기 조절용)
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        // placeholder에서는 기본 폰트 설정, 기본 배경 이미지, 기본 테마를 사용
        SimpleEntry(date: Date(), quote: "로딩 중...", fontSetting: "고양일산 L", backgroundImageData: nil, currentTheme: "라이트")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let quote = loadQuote()
        let fontSetting = loadFontSetting() // 폰트 설정 로드
        let backgroundImageData = loadBackgroundImageData() // 배경 이미지 데이터 로드
        let currentTheme = loadThemeSetting() // 테마 설정 로드

        completion(SimpleEntry(date: Date(), quote: quote, fontSetting: fontSetting, backgroundImageData: backgroundImageData, currentTheme: currentTheme))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        var entries: [SimpleEntry] = []

        let currentDate = Date()
        let calendar = Calendar.current
        
        // 현재 시간부터 24시간 동안 30분 간격으로 엔트리 생성
        for offset in 0..<48 { // 24시간 * 2 (30분 간격) = 48개 엔트리
            guard let entryDate = calendar.date(byAdding: .minute, value: offset * 30, to: currentDate) else {
                continue
            }

            let quote = loadQuote() // 각 엔트리마다 새로운 문구를 로드하거나, 동일한 문구를 사용
            let fontSetting = loadFontSetting()
            let backgroundImageData = loadBackgroundImageData()
            let currentTheme = loadThemeSetting()

            let entry = SimpleEntry(date: entryDate, quote: quote, fontSetting: fontSetting, backgroundImageData: backgroundImageData, currentTheme: currentTheme)
            entries.append(entry)
        }

        // 모든 엔트리가 표시된 후 위젯을 다시 업데이트하도록 설정
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    func loadQuote() -> String {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        return defaults?.string(forKey: AppConstants.todayQuoteKey) ?? "위젯 문구 없음"
    }

    // 폰트 설정을 앱 그룹 UserDefaults에서 로드하는 함수
    func loadFontSetting() -> String {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        return defaults?.string(forKey: "font") ?? "고양일산 L" // UserSettings에서 사용한 키 "font"와 동일하게
    }

    // 추가: 배경 이미지 데이터를 앱 그룹 UserDefaults에서 로드하는 함수
    func loadBackgroundImageData() -> Data? {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        return defaults?.data(forKey: "backgroundImageData")
    }

    // 추가: 테마 설정을 앱 그룹 UserDefaults에서 로드하는 함수
    func loadThemeSetting() -> String {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        return defaults?.string(forKey: "theme") ?? "라이트" // UserSettings에서 사용한 키 "theme"와 동일하게
    }
}

struct TOMOWidgetEntryView : View {
    var entry: Provider.Entry

    // 위젯 패밀리를 감지하기 위한 Environment 변수
    @Environment(\.widgetFamily) var family // <-- 이 줄 추가

    // 위젯에서 사용할 폰트 스타일을 결정하는 연산 프로퍼티
    var widgetFontStyle: Font {
        let baseSize: CGFloat
        switch family { // <-- widgetFamily에 따라 폰트 크기 조절
        case .systemSmall:
            baseSize = 15 // 작은 위젯
        case .systemMedium:
            baseSize = 20 // 중간 위젯 (현재 사용 중인 기본 크기)
        case .systemLarge:
            baseSize = 25 // 큰 위젯
        case .systemExtraLarge: // iPad 전용 (필요하다면 추가)
            baseSize = 30
        @unknown default:
            baseSize = 20 // 알 수 없는 위젯 크기
        }

        if entry.fontSetting == "고양일산 L" {
            return Font.custom("Goyangilsan L", size: baseSize) // PostScript 이름을 정확히 확인하여 사용
        } else if entry.fontSetting == "고양일산 R" {
            return Font.custom("Goyangilsan R", size: baseSize) // PostScript 이름을 정확히 확인하여 사용
        } else {
            return .body
        }
    }

    // 위젯에서 사용할 ColorScheme 결정
    var widgetPreferredColorScheme: ColorScheme {
        entry.currentTheme == "다크" ? .dark : .light
    }

    var body: some View {
        ZStack {
            // GeometryReader를 ZStack 바로 아래에 배치하여 위젯의 전체 공간을 읽습니다.
            GeometryReader { geometry in
                // 배경 이미지가 있을 경우 표시
                if let imageData = entry.backgroundImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill) // 프레임을 채우도록 (잘릴 수 있음)
                        // 위젯 크기보다 약간 더 크게 프레임을 설정
                        .frame(width: geometry.size.width * 1.3, height: geometry.size.height * 1.3)
                        .offset(x: -geometry.size.width * 0.15, y: -geometry.size.height * 0.15) // 중앙 정렬을 위해 오프셋 조정
                        // .edgesIgnoringSafeArea(.all) // GeometryReader 안에서는 필요 없을 수 있습니다.
                        .overlay(
                            Rectangle()
                                .fill(widgetPreferredColorScheme == .dark ?
                                      Color.black.opacity(0.5) :
                                      Color.white.opacity(0.5)
                                )
                                // 오버레이도 이미지와 똑같은 크기, 위치로 설정
                                .frame(width: geometry.size.width * 2, height: geometry.size.height * 2) // 이미지와 동일한 frame
                                .offset(x: -geometry.size.width * 0.05, y: -geometry.size.height * 0.05) // 이미지와 동일한 offset
                                .edgesIgnoringSafeArea(.all) // 오버레이가 안전 영역까지 덮도록
                        )
                } else {
                    // 배경 이미지가 없을 경우 기본 배경색 유지
                    Color(.systemBackground)
                        .edgesIgnoringSafeArea(.all) // GeometryReader 안에서도 필요할 수 있습니다.
                }
            } // End of GeometryReader
            // GeometryReader의 콘텐츠가 ZStack의 배경이 되도록 합니다.

            Text(entry.quote)
                .multilineTextAlignment(.center)
                .padding()
                .font(widgetFontStyle) // 위젯 폰트 스타일 적용
                // 위젯 텍스트 색상도 테마에 따라 조절
                .foregroundColor(widgetPreferredColorScheme == .dark ? .white : .black)
        }
        // 위젯은 .preferredColorScheme modifier를 직접 지원하지 않을 수 있으므로
        // 텍스트 색상을 직접 조절하는 것이 좋습니다.
        // .preferredColorScheme(widgetPreferredColorScheme) // 이 부분은 위젯에서 동작하지 않을 수 있음
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
        .description("오늘의 문구를 보여줍니다")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
