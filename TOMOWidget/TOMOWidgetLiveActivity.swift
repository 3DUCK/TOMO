//
// TOMOWidgetLiveActivity.swift
// TOMOWidget
//
// 이 파일은 '라이브 액티비티(Live Activity)' 위젯을 정의합니다.
// 라이브 액티비티는 실시간으로 업데이트되는 정보를 잠금 화면이나 다이내믹 아일랜드에 표시하여
// 사용자가 앱을 열지 않고도 최신 정보를 확인할 수 있도록 하는 기능입니다.
// 이 예시에서는 이모지(`emoji`)를 사용하여 실시간 업데이트를 시뮬레이션합니다.
//
// 주요 기능:
// - `ActivityAttributes` 프로토콜을 준수하여 라이브 액티비티의 정적 및 동적 속성을 정의합니다.
// - `WidgetConfiguration` 중 `ActivityConfiguration`을 사용하여 라이브 액티비티의 UI를 구성합니다.
// - 잠금 화면/배너 UI와 다이내믹 아일랜드(Expanded, Compact Leading/Trailing, Minimal) UI를 각각 정의합니다.
// - 미리 보기 기능을 통해 다양한 상태의 라이브 액티비티 UI를 개발 중에 확인할 수 있습니다.
//

import ActivityKit // 라이브 액티비티 관리를 위해 필요
import WidgetKit
import SwiftUI

/// 라이브 액티비티의 속성을 정의하는 구조체.
/// - `ContentState`: 활동 중 변경될 수 있는 동적인 상태(예: 이모지).
/// - `name`: 활동 중 변경되지 않는 고정된 속성(예: 활동 이름).
struct TOMOWidgetAttributes: ActivityAttributes {
    /// 라이브 액티비티의 동적인 상태를 정의하는 중첩 구조체.
    public struct ContentState: Codable, Hashable {
        var emoji: String // 예시로 사용된 동적인 이모지
    }

    /// 라이브 액티비티의 고정된 속성.
    var name: String
}

/// 라이브 액티비티 위젯을 정의하는 구조체.
struct TOMOWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        // `ActivityConfiguration`을 사용하여 `TOMOWidgetAttributes` 타입에 대한 라이브 액티비티를 구성합니다.
        ActivityConfiguration(for: TOMOWidgetAttributes.self) { context in
            // MARK: - 잠금 화면 / 배너 UI
            // 라이브 액티비티가 잠금 화면 또는 화면 상단 배너에 표시될 때의 UI를 정의합니다.
            VStack {
                Text("Hello \(context.state.emoji)") // `context.state`를 통해 동적 상태에 접근
            }
            .activityBackgroundTint(Color.cyan) // 배경 색상 틴트
            .activitySystemActionForegroundColor(Color.black) // 시스템 액션 버튼의 전경색 (예: 종료 버튼)

        } dynamicIsland: { context in
            // MARK: - 다이내믹 아일랜드 UI
            // iPhone 14 Pro 이상 모델의 다이내믹 아일랜드에 표시될 UI를 정의합니다.
            DynamicIsland {
                // 확장된(Expanded) 다이내믹 아일랜드 UI.
                // 여러 영역(leading, trailing, center, bottom)으로 구성될 수 있습니다.
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // 더 많은 콘텐츠를 추가할 수 있습니다.
                }
            } compactLeading: {
                // 작게 표시될 때 왼쪽 영역 UI
                Text("L")
            } compactTrailing: {
                // 작게 표시될 때 오른쪽 영역 UI
                Text("T \(context.state.emoji)")
            } minimal: {
                // 가장 최소한으로 표시될 때 UI
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com")) // 다이내믹 아일랜드 탭 시 이동할 URL
            .keylineTint(Color.red) // 다이내믹 아일랜드의 키라인 색상 틴트
        }
    }
}

// MARK: - Live Activity Preview Extensions

extension TOMOWidgetAttributes {
    /// 라이브 액티비티 미리 보기를 위한 정적 속성 예시.
    fileprivate static var preview: TOMOWidgetAttributes {
        TOMOWidgetAttributes(name: "World")
    }
}

extension TOMOWidgetAttributes.ContentState {
    /// 라이브 액티비티 미리 보기를 위한 동적 상태 예시 (스마일리).
    fileprivate static var smiley: TOMOWidgetAttributes.ContentState {
        TOMOWidgetAttributes.ContentState(emoji: "😀")
    }
    
    /// 라이브 액티비티 미리 보기를 위한 동적 상태 예시 (별 눈).
    fileprivate static var starEyes: TOMOWidgetAttributes.ContentState {
        TOMOWidgetAttributes.ContentState(emoji: "🤩")
    }
}

/// 라이브 액티비티 미리 보기를 생성하는 PreviewProvider.
/// "Notification"은 잠금 화면/배너 UI 미리 보기를 위한 레이블입니다.
#Preview("Notification", as: .content, using: TOMOWidgetAttributes.preview) {
    // 라이브 액티비티의 UI를 미리 보여줍니다.
    TOMOWidgetLiveActivity()
} contentStates: {
    // 미리 보기에서 사용할 동적 상태들을 정의합니다.
    TOMOWidgetAttributes.ContentState.smiley
    TOMOWidgetAttributes.ContentState.starEyes
}
