//
// AppConstants.swift
//
// 이 파일은 앱 전반에 걸쳐 사용되는 모든 상수들을 정의하는 구조체입니다.
// 앱 그룹 식별자, UserDefaults 키와 같이 변경되지 않는 고정된 값들을 한 곳에서 관리하여
// 코드의 가독성, 유지보수성, 그리고 일관성을 높이는 데 사용됩니다.
//
// 앱과 위젯 간의 데이터 공유를 위한 `appGroupID`와 오늘의 문구 정보를 저장하고
// 관리하기 위한 `UserDefaults` 키 등이 포함되어 있습니다.
//

import Foundation // 필요한 경우 Foundation 프레임워크 임포트

/// 앱 전반에 사용되는 상수들을 정의하는 구조체.
/// 그룹 컨테이너, 사용자 기본값(UserDefaults) 키 등 앱의 중요한 식별자를 관리합니다.
struct AppConstants {

    /// 앱 그룹 식별자.
    /// 앱과 위젯 간의 데이터 공유를 위해 사용됩니다.
    static let appGroupID = "group.geonu.tomo"

    /// 위젯에 오늘의 문구를 전달하기 위한 UserDefaults 키.
    static let todayQuoteKey = "todayQuote"

    /// 오늘의 문구가 생성된 날짜를 저장하기 위한 UserDefaults 키.
    /// 문구의 유효성 검사 및 업데이트 시 사용됩니다.
    static let todayQuoteDateKey = "todayQuoteDate"
}
