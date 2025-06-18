//
// FSCalendarRepresentable.swift
//
// 이 파일은 `FSCalendar`라는 UIKit 기반의 캘린더 라이브러리를 SwiftUI 뷰 계층에서 사용할 수 있도록
// `UIViewRepresentable` 프로토콜을 구현한 래퍼(wrapper) 뷰를 정의합니다.
// 시작일과 종료일을 선택하는 범위를 지원하며, 선택된 날짜 범위, 악센트 색상,
// 다크 모드 여부에 따라 캘린더의 시각적 요소를 동적으로 업데이트합니다.
//
// 주요 기능:
// - `FSCalendar` 인스턴스를 생성하고 SwiftUI 뷰처럼 사용할 수 있도록 연결합니다.
// - 사용자가 캘린더에서 날짜를 선택할 때 시작일과 종료일 범위를 관리하는 로직을 포함합니다.
// - 선택된 날짜 범위의 시각적 하이라이트(배경색, 텍스트 색상)를 사용자 정의합니다.
// - 오늘 날짜, 선택된 날짜, 범위 내 날짜, 주중/주말 텍스트 색상 등을 테마(다크/라이트 모드)에 따라 조정합니다.
// - 외부에서 주입되는 `calendarAccentColor`와 `isDarkMode` 값에 따라 캘린더의 스타일을 업데이트합니다.
//

import SwiftUI
import FSCalendar // FSCalendar 라이브러리 사용을 위해 필요

/// `FSCalendar` (UIKit 캘린더 라이브러리)를 SwiftUI 뷰로 래핑하여 사용합니다.
/// 날짜 범위 선택을 지원하며, 선택된 날짜, 강조 색상, 다크 모드에 따라 캘린더 UI를 업데이트합니다.
struct FSCalendarRepresentable: UIViewRepresentable {
    /// 선택된 시작 날짜를 바인딩합니다. (외부에서 제어 가능)
    @Binding var selectedStartDate: Date?
    /// 선택된 종료 날짜를 바인딩합니다. (외부에서 제어 가능)
    @Binding var selectedEndDate: Date?
    /// 날짜가 선택되거나 해제될 때 호출될 클로저.
    var onDatesSelected: (Date?, Date?) -> Void
    
    /// 캘린더에 적용될 강조 색상.
    var calendarAccentColor: Color
    /// 현재 앱의 다크 모드 여부.
    var isDarkMode: Bool

    /// `UIViewRepresentable`의 코디네이터 클래스.
    /// `FSCalendarDelegate`, `FSCalendarDataSource`, `FSCalendarDelegateAppearance` 프로토콜을 구현하여
    /// 캘린더의 동작과 외형을 제어합니다.
    class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
        var parent: FSCalendarRepresentable
        var resolvedAccentColor: Color // 실제 캘린더에 적용될 악센트 색상
        var isDarkMode: Bool // 현재 다크 모드 여부

        init(_ parent: FSCalendarRepresentable, resolvedAccentColor: Color, isDarkMode: Bool) {
            self.parent = parent
            self.resolvedAccentColor = resolvedAccentColor
            self.isDarkMode = isDarkMode
        }

        // MARK: - FSCalendarDataSource

        /// 특정 날짜에 표시될 이벤트의 개수를 반환합니다. (현재는 사용하지 않음)
        func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
            return 0 // 이벤트는 현재 표시하지 않습니다.
        }

        // MARK: - FSCalendarDelegate

        /// 날짜가 선택되었을 때 호출됩니다.
        /// 시작일과 종료일 선택 로직을 처리합니다.
        func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
            let currentCalendar = Calendar.current
            // 선택된 날짜를 자정 기준으로 정규화합니다.
            let selectedDay = currentCalendar.startOfDay(for: date)
            
            print("--- FSCalendar didSelect: \(selectedDay.formatted()) ---")

            if parent.selectedStartDate == nil {
                // Case 1: 시작 날짜가 없는 경우, 새로운 시작 날짜로 설정
                print("Case 1: No start date, setting new start date.")
                // 기존에 선택된 모든 날짜를 해제하여 새로운 선택을 준비합니다.
                for oldSelectedDate in calendar.selectedDates {
                    calendar.deselect(oldSelectedDate)
                }
                parent.selectedStartDate = selectedDay
                parent.selectedEndDate = nil
                calendar.select(selectedDay) // 새로 선택된 날짜를 캘린더에 반영
            } else if parent.selectedEndDate == nil {
                // Case 2: 시작 날짜는 있고 종료 날짜가 없는 경우, 종료 날짜로 설정
                print("Case 2: Start date exists, setting end date.")
                parent.selectedEndDate = selectedDay

                if let start = parent.selectedStartDate, let end = parent.selectedEndDate, start > end {
                    // 종료 날짜가 시작 날짜보다 이전인 경우, 두 날짜를 교환하여 정렬합니다.
                    print("  End date is before start date, swapping them.")
                    (parent.selectedStartDate, parent.selectedEndDate) = (end, start)
                }
                
                // 시작일과 종료일 사이의 모든 날짜를 선택합니다.
                if let start = parent.selectedStartDate, let end = parent.selectedEndDate {
                    let datesInBetween = self.dates(from: start, to: end)
                    print("  Dates in range to select: \(datesInBetween.map { $0.formatted(date: .abbreviated, time: .omitted) }.joined(separator: ", "))")
                    for d in datesInBetween {
                        // 이미 선택된 시작 날짜는 다시 선택하지 않도록 합니다.
                        if currentCalendar.startOfDay(for: d) != currentCalendar.startOfDay(for: start) {
                            calendar.select(d, scrollToDate: false)
                        }
                    }
                }
            } else {
                // Case 3: 시작 날짜와 종료 날짜가 모두 있는 경우, 선택을 초기화하고 새로운 시작 날짜로 설정
                print("Case 3: Both start and end dates exist, resetting selection.")
                // 기존에 선택된 모든 날짜를 해제합니다.
                for oldSelectedDate in calendar.selectedDates {
                    calendar.deselect(oldSelectedDate)
                }
                parent.selectedStartDate = selectedDay
                parent.selectedEndDate = nil
                calendar.select(selectedDay) // 새로 선택된 날짜를 캘린더에 반영
            }
            
            print("  Current selected range: \(parent.selectedStartDate?.formatted() ?? "nil") ~ \(parent.selectedEndDate?.formatted() ?? "nil")")
            // 외부 콜백 함수를 호출하여 선택된 날짜 범위를 전달합니다.
            parent.onDatesSelected(parent.selectedStartDate, parent.selectedEndDate)
            calendar.reloadData() // 캘린더 UI를 강제로 다시 로드하여 변경 사항 반영
            print("--- End of didSelect ---")
        }
        
        /// 날짜가 선택 해제되었을 때 호출됩니다.
        /// 선택 해제된 날짜가 시작일/종료일 범위에 따라 선택 상태를 조정합니다.
        func calendar(_ calendar: FSCalendar, didDeselect date: Date, at monthPosition: FSCalendarMonthPosition) {
            let currentCalendar = Calendar.current
            let deselectedDay = currentCalendar.startOfDay(for: date)
            
            print("--- FSCalendar didDeselect: \(deselectedDay.formatted()) ---")

            if let startDate = parent.selectedStartDate, let endDate = parent.selectedEndDate {
                // 범위가 선택된 상태에서 시작일이 해제되면 전체 범위를 리셋합니다.
                if deselectedDay == currentCalendar.startOfDay(for: startDate) {
                    print("  Deselecting start date. Resetting whole range.")
                    parent.selectedStartDate = nil
                    parent.selectedEndDate = nil
                    for d in calendar.selectedDates {
                        calendar.deselect(d) // 모든 선택된 날짜 해제
                    }
                } else if deselectedDay == currentCalendar.startOfDay(for: endDate) {
                    // 범위가 선택된 상태에서 종료일이 해제되면 종료일만 리셋하고 시작일은 유지합니다.
                    print("  Deselecting end date. Keeping start date.")
                    parent.selectedEndDate = nil
                    for d in calendar.selectedDates {
                        // 시작일이 아닌 다른 선택된 날짜들을 해제합니다.
                        if currentCalendar.startOfDay(for: d) != currentCalendar.startOfDay(for: startDate) {
                            calendar.deselect(d)
                        }
                    }
                } else {
                    // 범위 내의 중간 날짜가 해제되면 전체 범위를 리셋합니다.
                    print("  Deselecting a date within range. Resetting whole range.")
                    parent.selectedStartDate = nil
                    parent.selectedEndDate = nil
                    for d in calendar.selectedDates {
                        calendar.deselect(d)
                    }
                }
            } else if let startDate = parent.selectedStartDate {
                // 단일 시작일만 선택된 상태에서 해당 날짜가 해제되면 시작일을 리셋합니다.
                if deselectedDay == currentCalendar.startOfDay(for: startDate) {
                    print("  Deselecting single start date.")
                    parent.selectedStartDate = nil
                    calendar.deselect(deselectedDay)
                }
            }

            print("  Current selected range after deselect: \(parent.selectedStartDate?.formatted() ?? "nil") ~ \(parent.selectedEndDate?.formatted() ?? "nil")")
            // 외부 콜백 함수를 호출하여 업데이트된 선택 날짜 범위를 전달합니다.
            parent.onDatesSelected(parent.selectedStartDate, parent.selectedEndDate)
            calendar.reloadData() // 캘린더 UI를 강제로 다시 로드하여 변경 사항 반영
            print("--- End of didDeselect ---")
        }

        // MARK: - FSCalendarDelegateAppearance for Highlighting

        /// 선택된 날짜의 채우기 색상을 설정합니다.
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillSelectionColorFor date: Date) -> UIColor? {
            // 선택된 날짜의 배경색을 회색으로 설정합니다.
            return UIColor.systemGray
        }
        
        /// 오늘 날짜의 기본 채우기 색상을 설정합니다.
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
            let currentCalendar = Calendar.current
            if currentCalendar.isDateInToday(date) {
                // 오늘 날짜의 배경색을 밝은 회색으로 설정합니다.
                return UIColor.lightGray
            }
            return nil // 그 외 날짜는 기본값 사용
        }

        /// 날짜 텍스트의 기본 색상을 설정합니다.
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
            let currentCalendar = Calendar.current
            let targetDay = currentCalendar.startOfDay(for: date)

            // 시작일과 종료일 범위 내의 날짜는 흰색 텍스트로 표시합니다.
            if let start = parent.selectedStartDate, let end = parent.selectedEndDate {
                let startOfRange = currentCalendar.startOfDay(for: start)
                let endOfRange = currentCalendar.startOfDay(for: end)

                if targetDay >= startOfRange && targetDay <= endOfRange {
                    return UIColor.white
                }
            } else if let start = parent.selectedStartDate {
                // 단일 시작일만 선택된 경우 해당 날짜를 흰색 텍스트로 표시합니다.
                let startOfRange = currentCalendar.startOfDay(for: start)
                if targetDay == startOfRange {
                    return UIColor.white
                }
            }
            // 그 외의 날짜는 다크 모드 여부에 따라 검정 또는 흰색으로 표시합니다.
            return isDarkMode ? .white : .black
        }
        
        /// 오늘 날짜 텍스트의 색상을 설정합니다.
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleTodayColorFor date: Date) -> UIColor? {
            // 외부에서 주입된 악센트 색상으로 설정합니다.
            return UIColor(resolvedAccentColor)
        }
        
        /// 요일(평일/주말) 텍스트 색상을 설정합니다.
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, weekdayTextColorFor date: Date) -> UIColor? {
            let weekday = Calendar.current.component(.weekday, from: date)
            // 토요일(7)과 일요일(1)은 빨간색으로 표시
            if weekday == 7 || weekday == 1 {
                return UIColor.systemRed
            }
            // 그 외 요일은 다크 모드 여부에 따라 밝은 회색 또는 진한 회색으로 표시
            return isDarkMode ? .lightGray : .darkGray
        }

        // MARK: - Helper to get dates in range

        /// 주어진 시작 날짜와 종료 날짜 사이의 모든 날짜를 포함하는 배열을 반환합니다.
        /// - Parameters:
        ///   - startDate: 시작 날짜.
        ///   - endDate: 종료 날짜.
        /// - Returns: 시작 날짜부터 종료 날짜까지의 모든 날짜(`Date`) 객체 배열.
        private func dates(from startDate: Date, to endDate: Date) -> [Date] {
            let calendar = Calendar.current
            var dates: [Date] = []
            
            // 시작일과 종료일을 올바른 순서로 정렬합니다.
            let orderedStartDate = min(startDate, endDate)
            let orderedEndDate = max(startDate, endDate)
            
            var currentDate = calendar.startOfDay(for: orderedStartDate) // 시작일의 자정부터 시작

            // 현재 날짜가 종료일의 자정보다 작거나 같을 때까지 반복하여 날짜를 추가합니다.
            while currentDate <= calendar.startOfDay(for: orderedEndDate) {
                dates.append(currentDate)
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                currentDate = nextDate
            }
            return dates
        }
    }

    // MARK: - UIViewRepresentable Protocol Methods

    /// SwiftUI 뷰 계층에 표시될 `FSCalendar` 인스턴스를 생성하고 초기 설정합니다.
    func makeUIView(context: Context) -> FSCalendar {
        let calendar = FSCalendar()
        calendar.delegate = context.coordinator // 코디네이터를 델리게이트로 설정
        calendar.dataSource = context.coordinator // 코디네이터를 데이터 소스로 설정

        calendar.scope = .month // 캘린더 범위를 월 단위로 설정
        calendar.firstWeekday = 2 // 월요일을 한 주의 시작으로 설정 (1: 일요일, 2: 월요일)

        // 캘린더의 폰트 설정
        calendar.appearance.headerTitleFont = .systemFont(ofSize: 20, weight: .bold) // 헤더(월/년) 타이틀 폰트
        calendar.appearance.weekdayFont = .systemFont(ofSize: 15, weight: .semibold) // 요일 폰트
        calendar.appearance.titleFont = .systemFont(ofSize: 17) // 날짜 숫자 폰트
        
        // 이벤트 기본 색상 (현재는 이벤트가 없으므로 큰 영향 없음)
        calendar.appearance.eventDefaultColor = UIColor.systemGreen
        
        // MARK: 배경색을 투명으로 설정하여 SwiftUI 배경이 보이도록 합니다.
        calendar.backgroundColor = .clear
        
        // 초기 테마에 따른 텍스트 색상 설정
        calendar.appearance.titleDefaultColor = isDarkMode ? .white : .black // 날짜 숫자 기본 색상
        calendar.appearance.weekdayTextColor = isDarkMode ? .lightGray : .darkGray // 요일 텍스트 색상
        calendar.appearance.headerTitleColor = isDarkMode ? .white : .black // 헤더 타이틀 색상
        
        // 오늘 날짜의 배경색과 텍스트 색상 설정 (악센트 색상 사용)
        calendar.appearance.todayColor = UIColor(calendarAccentColor.opacity(0.2)) // 오늘 날짜 배경 (투명도 적용)
        calendar.appearance.titleTodayColor = UIColor(calendarAccentColor) // 오늘 날짜 숫자 색상
        
        calendar.allowsMultipleSelection = true // 다중 날짜 선택 허용
        calendar.swipeToChooseGesture.isEnabled = true // 스와이프하여 날짜 선택 제스처 활성화

        return calendar
    }

    /// SwiftUI 뷰의 상태가 변경될 때 `FSCalendar` (UIKit 뷰)를 업데이트합니다.
    func updateUIView(_ uiView: FSCalendar, context: Context) {
        // MARK: 배경색을 투명으로 설정 (업데이트 시에도 유지)
        uiView.backgroundColor = .clear
        
        // 테마 변경에 따라 텍스트 색상 업데이트
        uiView.appearance.titleDefaultColor = isDarkMode ? .white : .black
        uiView.appearance.weekdayTextColor = isDarkMode ? .lightGray : .darkGray
        uiView.appearance.headerTitleColor = isDarkMode ? .white : .black
        
        // 코디네이터에 업데이트된 악센트 색상과 다크 모드 여부를 전달합니다.
        context.coordinator.resolvedAccentColor = calendarAccentColor
        context.coordinator.isDarkMode = isDarkMode

        uiView.reloadData() // 캘린더 데이터를 다시 로드하여 UI 변경 사항을 반영
    }

    /// `UIViewRepresentable`의 코디네이터 인스턴스를 생성합니다.
    /// 코디네이터는 SwiftUI 뷰와 UIKit 뷰 간의 상호작용 및 델리게이트를 처리합니다.
    func makeCoordinator() -> Coordinator {
        Coordinator(self, resolvedAccentColor: calendarAccentColor, isDarkMode: isDarkMode)
    }
}
