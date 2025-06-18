//
// TOMOWidgetControl.swift
// TOMOWidget
//
// 이 파일은 홈 화면에서 특정 앱 기능을 직접 제어할 수 있는 '제어 위젯(Control Widget)'을 정의합니다.
// iOS 17부터 도입된 새로운 위젯 타입으로, 사용자 상호작용을 통해 앱의 기능을 실행할 수 있도록 합니다.
// 이 예시에서는 타이머를 시작/정지하는 가상의 기능을 제공합니다.
//
// 주요 기능:
// - `ControlWidget` 프로토콜을 준수하여 상호작용 가능한 위젯 UI를 구성합니다.
// - `ControlWidgetToggle`을 사용하여 ON/OFF 상태를 토글하는 버튼을 구현합니다.
// - `AppIntents` 프레임워크를 사용하여 위젯에서 앱의 특정 동작(`StartTimerIntent`)을 호출합니다.
// - `ControlValueProvider`를 통해 위젯의 현재 상태(예: 타이머 실행 여부)를 제공합니다.
//

import AppIntents // 위젯에서 앱 기능 호출을 위해 필요
import SwiftUI
import WidgetKit

/// 앱의 특정 기능을 제어할 수 있는 제어 위젯.
/// 이 예시에서는 타이머 시작/정지 기능을 가상으로 구현합니다.
struct TOMOWidgetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        // `StaticControlConfiguration`은 위젯의 종류와 데이터 제공자를 정의합니다.
        StaticControlConfiguration(
            kind: "geonu.hansung.ac.kr.TOMO.TOMOWidget", // 이 위젯의 고유 ID (메인 위젯과 동일한 kind를 사용하거나 다른 kind 사용 가능)
            provider: Provider() // 위젯의 현재 상태를 제공하는 프로바이더
        ) { value in // `value`는 `Provider`가 제공하는 Bool 값 (여기서는 타이머 실행 여부)
            // 위젯에 표시될 UI를 정의합니다.
            ControlWidgetToggle(
                "Start Timer", // 토글의 레이블 텍스트
                isOn: value,   // 토글의 현재 상태 (Provider에서 가져온 값)
                action: StartTimerIntent() // 토글 시 실행될 AppIntent
            ) { isRunning in // isRunning은 토글의 현재 상태를 나타내는 바인딩
                Label(isRunning ? "On" : "Off", systemImage: "timer") // 토글의 아이콘과 텍스트
            }
        }
        .displayName("Timer") // 위젯 갤러리 및 위젯에 표시될 이름
        .description("A an example control that runs a timer.") // 위젯 설명
    }
}

extension TOMOWidgetControl {
    /// 제어 위젯의 현재 값을 제공하는 프로바이더.
    struct Provider: ControlValueProvider {
        /// 미리 보기에서 사용될 기본값.
        var previewValue: Bool {
            false // 미리 보기에서는 타이머가 꺼진 상태로 시작
        }

        /// 위젯의 현재 상태(값)를 비동기적으로 제공합니다.
        func currentValue() async throws -> Bool {
            // 실제 앱에서 타이머가 실행 중인지 확인하는 로직이 여기에 들어갑니다.
            // 예시로 `true`를 반환하지만, 실제 앱의 상태를 반영해야 합니다.
            let isRunning = true // Check if the timer is running
            return isRunning
        }
    }
}

/// 위젯에서 호출될 타이머 시작/정지 AppIntent.
/// `SetValueIntent`는 특정 값을 설정하는 액션에 사용됩니다.
struct StartTimerIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Start a timer" // 인텐트의 표시 이름

    /// 위젯 토글의 상태와 연동될 매개변수.
    @Parameter(title: "Timer is running")
    var value: Bool

    /// 인텐트가 실행될 때 수행될 비동기 작업.
    func perform() async throws -> some IntentResult {
        // `value`에 따라 타이머를 시작하거나 중지하는 실제 로직이 여기에 들어갑니다.
        print("StartTimerIntent performed: value = \(value)")
        return .result() // 작업 성공을 알리는 결과 반환
    }
}
