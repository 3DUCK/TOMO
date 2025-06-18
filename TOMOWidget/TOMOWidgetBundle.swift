//
// TOMOWidgetBundle.swift
// TOMOWidget
//
// 이 파일은 앱에 포함된 모든 위젯(Widget)을 묶어서 시스템에 등록하는 역할을 합니다.
// WidgetBundle 프로토콜을 준수하며, 앱이 제공하는 다양한 위젯들을 한곳에서 선언하여
// iOS 시스템이 이 위젯들을 발견하고 관리할 수 있도록 합니다.
//
// 주요 기능:
// - 앱의 모든 위젯(정적 위젯, 제어 위젯, 라이브 액티비티)을 하나의 번들로 묶어 제공합니다.
// - 위젯 시스템이 이 번들을 통해 앱의 위젯들을 인식하고 갤러리 등에 표시할 수 있도록 합니다.
//

import WidgetKit
import SwiftUI

/// TOMO 앱의 모든 위젯을 포함하는 위젯 번들.
/// `@main` 어트리뷰트가 없으므로 이 파일은 위젯 확장(Widget Extension)의 진입점이 됩니다.
struct TOMOWidgetBundle: WidgetBundle {
    /// 이 번들에 포함될 위젯들을 정의합니다.
    var body: some Widget {
        TOMOWidget()          // 오늘의 문구를 표시하는 일반 위젯
        TOMOWidgetControl()   // 제어 기능을 제공하는 위젯
        TOMOWidgetLiveActivity() // 실시간 정보를 표시하는 라이브 액티비티 위젯
    }
}
