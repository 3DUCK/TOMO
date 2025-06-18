//
// TOMOWidget.swift
//
// 이 파일은 TOMO 앱의 위젯 확장을 정의합니다.
// 홈 화면 위젯에 '오늘의 문구'를 표시하며, 앱에서 설정한 폰트, 배경 이미지, 테마 설정을 반영합니다.
//
// 주요 기능:
// - `SimpleEntry`: 위젯 타임라인의 각 시점에 표시될 데이터 모델 (문구, 폰트, 배경 이미지, 테마).
// - `Provider`: 위젯 타임라인을 생성하고, 위젯에 표시될 데이터를 제공합니다.
//   - 앱 그룹 `UserDefaults`를 통해 메인 앱과 데이터를 공유하여 문구, 폰트, 배경 이미지, 테마 설정을 로드합니다.
//   - 일정 간격으로 위젯을 업데이트하기 위한 타임라인 정책을 설정합니다.
// - `TOMOWidgetEntryView`: `SimpleEntry` 데이터를 기반으로 위젯 UI를 렌더링합니다.
//   - 위젯 크기(`widgetFamily`)에 따라 폰트 크기를 동적으로 조절합니다.
//   - 설정된 배경 이미지를 위젯 배경으로 표시하고, 테마에 따라 오버레이를 적용하여 가독성을 높입니다.
// - `TOMOWidget`: 위젯의 메인 구성 요소로, 위젯의 종류, 표시 이름, 설명을 정의하고 지원하는 위젯 패밀리를 지정합니다.
//

import WidgetKit
import SwiftUI
import UIKit // UIImage를 사용하기 위해 필요 (위젯에서도 이미지 데이터 사용 가능)

// AppConstants는 위젯 타겟에도 추가되어 있어야 합니다! (앱 그룹 UserDefaults 접근용)

/// 위젯 타임라인의 각 시점에 표시될 데이터를 정의하는 구조체.
struct SimpleEntry: TimelineEntry {
    let date: Date // 엔트리의 날짜 및 시간
    let quote: String // 표시될 오늘의 문구
    let fontSetting: String // 사용자 설정 폰트 이름
    let backgroundImageData: Data? // 사용자 설정 배경 이미지 데이터 (Optional)
    let currentTheme: String // 사용자 설정 테마 (예: "라이트", "다크")
}

/// 위젯의 데이터를 제공하고 타임라인을 관리하는 프로바이더.
struct Provider: TimelineProvider {
    /// 위젯이 로드되거나 데이터를 준비하는 동안 표시될 플레이스홀더 엔트리.
    func placeholder(in context: Context) -> SimpleEntry {
        // 기본 폰트, 배경 없음, 라이트 테마로 플레이스홀더를 제공합니다.
        SimpleEntry(date: Date(), quote: "로딩 중...", fontSetting: "고양일산 L", backgroundImageData: nil, currentTheme: "라이트")
    }

    /// 위젯 갤러리에서 스냅샷을 생성하거나 위젯을 처음 로드할 때 사용될 단일 엔트리.
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let quote = loadQuote() // 현재 저장된 문구 로드
        let fontSetting = loadFontSetting() // 폰트 설정 로드
        let backgroundImageData = loadBackgroundImageData() // 배경 이미지 데이터 로드
        let currentTheme = loadThemeSetting() // 테마 설정 로드

        let entry = SimpleEntry(date: Date(), quote: quote, fontSetting: fontSetting, backgroundImageData: backgroundImageData, currentTheme: currentTheme)
        completion(entry)
    }

    /// 위젯이 업데이트될 타임라인을 정의하는 메서드.
    /// 여러 개의 `SimpleEntry`를 생성하여 미래의 특정 시점에 위젯이 업데이트되도록 예약합니다.
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        var entries: [SimpleEntry] = []

        let currentDate = Date()
        let calendar = Calendar.current
        
        // 현재 시간부터 24시간 동안 30분 간격으로 엔트리 생성 (총 48개 엔트리)
        for offset in 0..<48 {
            guard let entryDate = calendar.date(byAdding: .minute, value: offset * 30, to: currentDate) else {
                continue // 날짜 계산 실패 시 건너뛰기
            }

            // 각 엔트리마다 현재 저장된 문구, 폰트, 배경 이미지, 테마를 로드
            // (여기서는 모든 엔트리가 동일한 문구/설정을 사용하도록 구현되어 있습니다.
            // 필요에 따라 각 엔트리마다 다른 문구를 로드하도록 변경할 수 있습니다.)
            let quote = loadQuote()
            let fontSetting = loadFontSetting()
            let backgroundImageData = loadBackgroundImageData()
            let currentTheme = loadThemeSetting()

            let entry = SimpleEntry(date: entryDate, quote: quote, fontSetting: fontSetting, backgroundImageData: backgroundImageData, currentTheme: currentTheme)
            entries.append(entry)
        }

        // 모든 엔트리가 표시된 후 위젯을 다시 업데이트하도록 설정 (`.atEnd` 정책)
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    // MARK: - Helper Functions (UserDefaults에서 데이터 로드)

    /// 앱 그룹 UserDefaults에서 오늘의 문구를 로드합니다.
    /// - Returns: 저장된 문구 문자열. 없으면 기본값 "위젯 문구 없음" 반환.
    func loadQuote() -> String {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        return defaults?.string(forKey: AppConstants.todayQuoteKey) ?? "위젯 문구 없음"
    }

    /// 앱 그룹 UserDefaults에서 폰트 설정을 로드합니다.
    /// - Returns: 저장된 폰트 설정 문자열. 없으면 기본값 "고양일산 L" 반환.
    func loadFontSetting() -> String {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        return defaults?.string(forKey: "font") ?? "고양일산 L" // UserSettings에서 사용한 키 "font"와 동일
    }

    /// 앱 그룹 UserDefaults에서 배경 이미지 데이터를 로드합니다.
    /// - Returns: 저장된 배경 이미지 `Data`. 없으면 `nil` 반환.
    func loadBackgroundImageData() -> Data? {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        return defaults?.data(forKey: "backgroundImageData") // UserSettings에서 사용한 키 "backgroundImageData"와 동일
    }

    /// 앱 그룹 UserDefaults에서 테마 설정을 로드합니다.
    /// - Returns: 저장된 테마 설정 문자열. 없으면 기본값 "라이트" 반환.
    func loadThemeSetting() -> String {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        return defaults?.string(forKey: "theme") ?? "라이트" // UserSettings에서 사용한 키 "theme"와 동일
    }
}

/// 위젯의 UI를 정의하는 뷰. `SimpleEntry` 데이터를 사용하여 내용을 표시합니다.
struct TOMOWidgetEntryView : View {
    var entry: Provider.Entry

    /// 현재 위젯 패밀리(크기)를 감지하기 위한 환경 변수.
    @Environment(\.widgetFamily) var family

    /// 위젯 패밀리에 따라 폰트 크기를 동적으로 조절하여 폰트 스타일을 반환하는 연산 프로퍼티.
    var widgetFontStyle: Font {
        let baseSize: CGFloat
        switch family {
        case .systemSmall:
            baseSize = 15 // 작은 위젯
        case .systemMedium:
            baseSize = 20 // 중간 위젯
        case .systemLarge:
            baseSize = 25 // 큰 위젯
        case .systemExtraLarge: // iPad 전용 (필요하다면 추가)
            baseSize = 30
        @unknown default:
            baseSize = 20 // 알 수 없는 위젯 크기 또는 새로운 위젯 패밀리에 대한 기본값
        }

        // `fontSetting`에 따라 커스텀 폰트를 적용합니다. PostScript 이름을 정확히 사용해야 합니다.
        if entry.fontSetting == "고양일산 L" {
            return Font.custom("Goyangilsan L", size: baseSize)
        } else if entry.fontSetting == "고양일산 R" {
            return Font.custom("Goyangilsan R", size: baseSize)
        } else if entry.fontSetting == "조선일보명조" {
            return Font.custom("ChosunilboNM", size: baseSize)
        } else {
            return .body // 일치하는 폰트가 없으면 시스템 기본 폰트 사용
        }
    }

    /// 위젯에서 사용할 `ColorScheme`을 결정하는 연산 프로퍼티 (테마 설정에 기반).
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
                        .aspectRatio(contentMode: .fill) // 프레임을 채우도록 (이미지 일부가 잘릴 수 있음)
                        // 위젯의 크기보다 약간 더 크게 프레임을 설정하고 오프셋을 주어 중앙에 정렬 시도
                        // 이렇게 하면 위젯 가장자리에 배경 이미지가 잘려 보이지 않도록 합니다.
                        .frame(width: geometry.size.width * 1.3, height: geometry.size.height * 1.3)
                        .offset(x: -geometry.size.width * 0.15, y: -geometry.size.height * 0.15) // 중앙 정렬을 위한 오프셋 조정
                        .clipped() // 프레임을 벗어나는 부분은 잘라냅니다.
                        .overlay(
                            // 테마에 따라 이미지 위에 반투명 오버레이를 적용하여 텍스트 가독성을 높입니다.
                            Rectangle()
                                .fill(widgetPreferredColorScheme == .dark ?
                                      Color.black.opacity(0.5) : // 다크 테마일 때 어둡게
                                      Color.white.opacity(0.5)    // 라이트 테마일 때 밝게
                                )
                                // 오버레이도 이미지와 동일한 크기, 위치로 설정
                                .frame(width: geometry.size.width * 1.3, height: geometry.size.height * 1.3)
                                .offset(x: -geometry.size.width * 0.15, y: -geometry.size.height * 0.15)
                                .clipped() // 오버레이도 프레임을 벗어나는 부분은 잘라냅니다.
                        )
                } else {
                    // 배경 이미지가 없을 경우 시스템 기본 배경색 사용
                    Color(.systemBackground)
                        .edgesIgnoringSafeArea(.all) // 위젯의 모든 공간을 채우도록
                }
            } // End of GeometryReader
            // GeometryReader의 콘텐츠가 ZStack의 배경이 되도록 합니다.

            // MARK: - 문구 텍스트 레이어
            Text("\"" + entry.quote + "\"")
                .multilineTextAlignment(.center) // 여러 줄 텍스트 중앙 정렬
                .padding() // 텍스트 주변 패딩
                .font(widgetFontStyle) // 위젯 폰트 스타일 적용
                .lineSpacing(5) // 줄 간격 설정
                // 위젯 텍스트 색상도 테마에 따라 조절
                .foregroundColor(widgetPreferredColorScheme == .dark ? .white : .black)
        }
        // 참고: 위젯에서는 `.preferredColorScheme` modifier가 메인 앱처럼 완벽하게 동작하지 않을 수 있습니다.
        // 대신 텍스트 및 오버레이 색상을 직접 `widgetPreferredColorScheme`에 따라 조절하는 것이 더 안정적입니다.
    }
}

/// TOMO 위젯의 메인 정의.
/// `@main` 어트리뷰트를 통해 위젯의 시작점을 선언합니다.
@main
struct TOMOWidget: Widget {
    let kind: String = "TOMOWidget" // 위젯을 식별하는 고유 문자열 ID

    /// 위젯의 구성을 정의합니다.
    var body: some WidgetConfiguration {
        // `StaticConfiguration`을 사용하여 위젯이 사용자 설정 없이 고정된 데이터를 표시함을 나타냅니다.
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TOMOWidgetEntryView(entry: entry) // 엔트리 데이터를 사용하여 뷰 생성
        }
        .configurationDisplayName("TOMO 위젯") // 위젯 갤러리에 표시될 이름
        .description("오늘의 문구를 보여줍니다") // 위젯 갤러리에 표시될 설명
        // 이 위젯이 지원하는 위젯 패밀리(크기)를 지정합니다.
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
