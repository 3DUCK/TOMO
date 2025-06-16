import SwiftUI
import FSCalendar

struct FSCalendarRepresentable: UIViewRepresentable {
    @Binding var selectedStartDate: Date?
    @Binding var selectedEndDate: Date?
    var onDatesSelected: (Date?, Date?) -> Void
    
    var calendarAccentColor: Color
    var isDarkMode: Bool

    class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
        var parent: FSCalendarRepresentable
        var resolvedAccentColor: Color
        var isDarkMode: Bool

        init(_ parent: FSCalendarRepresentable, resolvedAccentColor: Color, isDarkMode: Bool) {
            self.parent = parent
            self.resolvedAccentColor = resolvedAccentColor
            self.isDarkMode = isDarkMode
        }

        // MARK: - FSCalendarDataSource
        func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
            return 0
        }

        // MARK: - FSCalendarDelegate
        func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
            let currentCalendar = Calendar.current
            let selectedDay = currentCalendar.startOfDay(for: date)
            
            print("--- FSCalendar didSelect: \(selectedDay.formatted()) ---")

            if parent.selectedStartDate == nil {
                print("Case 1: No start date, setting new start date.")
                for oldSelectedDate in calendar.selectedDates {
                    calendar.deselect(oldSelectedDate)
                }
                parent.selectedStartDate = selectedDay
                parent.selectedEndDate = nil
                calendar.select(selectedDay)
            } else if parent.selectedEndDate == nil {
                print("Case 2: Start date exists, setting end date.")
                parent.selectedEndDate = selectedDay

                if let start = parent.selectedStartDate, let end = parent.selectedEndDate, start > end {
                    print("  End date is before start date, swapping them.")
                    (parent.selectedStartDate, parent.selectedEndDate) = (end, start)
                }
                
                if let start = parent.selectedStartDate, let end = parent.selectedEndDate {
                    let datesInBetween = self.dates(from: start, to: end)
                    print("  Dates in range to select: \(datesInBetween.map { $0.formatted(date: .abbreviated, time: .omitted) }.joined(separator: ", "))")
                    for d in datesInBetween {
                        if currentCalendar.startOfDay(for: d) != currentCalendar.startOfDay(for: start) {
                            calendar.select(d, scrollToDate: false)
                        }
                    }
                }
            } else {
                print("Case 3: Both start and end dates exist, resetting selection.")
                for oldSelectedDate in calendar.selectedDates {
                    calendar.deselect(oldSelectedDate)
                }
                parent.selectedStartDate = selectedDay
                parent.selectedEndDate = nil
                calendar.select(selectedDay)
            }
            
            print("  Current selected range: \(parent.selectedStartDate?.formatted() ?? "nil") ~ \(parent.selectedEndDate?.formatted() ?? "nil")")
            parent.onDatesSelected(parent.selectedStartDate, parent.selectedEndDate)
            calendar.reloadData()
            print("--- End of didSelect ---")
        }
        
        func calendar(_ calendar: FSCalendar, didDeselect date: Date, at monthPosition: FSCalendarMonthPosition) {
            let currentCalendar = Calendar.current
            let deselectedDay = currentCalendar.startOfDay(for: date)
            
            print("--- FSCalendar didDeselect: \(deselectedDay.formatted()) ---")

            if let startDate = parent.selectedStartDate, let endDate = parent.selectedEndDate {
                if deselectedDay == currentCalendar.startOfDay(for: startDate) {
                    print("  Deselecting start date. Resetting whole range.")
                    parent.selectedStartDate = nil
                    parent.selectedEndDate = nil
                    for d in calendar.selectedDates {
                        calendar.deselect(d)
                    }
                } else if deselectedDay == currentCalendar.startOfDay(for: endDate) {
                    print("  Deselecting end date. Keeping start date.")
                    parent.selectedEndDate = nil
                    for d in calendar.selectedDates {
                        if currentCalendar.startOfDay(for: d) != currentCalendar.startOfDay(for: startDate) {
                            calendar.deselect(d)
                        }
                    }
                } else {
                    print("  Deselecting a date within range. Resetting whole range.")
                    parent.selectedStartDate = nil
                    parent.selectedEndDate = nil
                    for d in calendar.selectedDates {
                        calendar.deselect(d)
                    }
                }
            } else if let startDate = parent.selectedStartDate {
                if deselectedDay == currentCalendar.startOfDay(for: startDate) {
                    print("  Deselecting single start date.")
                    parent.selectedStartDate = nil
                    calendar.deselect(deselectedDay)
                }
            }

            print("  Current selected range after deselect: \(parent.selectedStartDate?.formatted() ?? "nil") ~ \(parent.selectedEndDate?.formatted() ?? "nil")")
            parent.onDatesSelected(parent.selectedStartDate, parent.selectedEndDate)
            calendar.reloadData()
            print("--- End of didDeselect ---")
        }

        // MARK: - FSCalendarDelegateAppearance for Highlighting
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillSelectionColorFor date: Date) -> UIColor? {
            let currentCalendar = Calendar.current
            let targetDay = currentCalendar.startOfDay(for: date)

            if let start = parent.selectedStartDate, let end = parent.selectedEndDate {
                let startOfRange = currentCalendar.startOfDay(for: start)
                let endOfRange = currentCalendar.startOfDay(for: end)

                if targetDay == startOfRange || targetDay == endOfRange {
                    // 시작일과 종료일은 악센트 색상 (진하게)
                    return UIColor(resolvedAccentColor.opacity(0.8))
                } else if targetDay >= startOfRange && targetDay <= endOfRange {
                    return UIColor(resolvedAccentColor.opacity(0.4))
                    // 범위 내 날짜는 회색 (다크 모드 고려)
                    // return isDarkMode ? UIColor.systemGray4.withAlphaComponent(0.6) : UIColor.lightGray.withAlphaComponent(0.6)
                }
            } else if let start = parent.selectedStartDate {
                let startOfRange = currentCalendar.startOfDay(for: start)
                if targetDay == startOfRange {
                    // 시작일만 선택된 경우, 약간 연한 악센트 색상
                    return UIColor(resolvedAccentColor.opacity(0.5))
                }
            }
            return UIColor(resolvedAccentColor) // 기본 선택 색상
        }

        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {
            return nil // 선택되지 않은 날짜는 기본 색상 사용
        }

        // 날짜 텍스트 색상을 설정합니다.
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
            let currentCalendar = Calendar.current
            let targetDay = currentCalendar.startOfDay(for: date)

            if let start = parent.selectedStartDate, let end = parent.selectedEndDate {
                let startOfRange = currentCalendar.startOfDay(for: start)
                let endOfRange = currentCalendar.startOfDay(for: end)

                if targetDay >= startOfRange && targetDay <= endOfRange {
                    return UIColor.white
                }
            } else if let start = parent.selectedStartDate {
                let startOfRange = currentCalendar.startOfDay(for: start)
                if targetDay == startOfRange {
                    return UIColor.white
                }
            }
            return isDarkMode ? .white : .black
        }
        
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleTodayColorFor date: Date) -> UIColor? {
            return UIColor(resolvedAccentColor)
        }
        
        
        // MARK: - Helper to get dates in range
        private func dates(from startDate: Date, to endDate: Date) -> [Date] {
            let calendar = Calendar.current
            var dates: [Date] = []
            
            let orderedStartDate = min(startDate, endDate)
            let orderedEndDate = max(startDate, endDate)
            
            var currentDate = calendar.startOfDay(for: orderedStartDate)

            while currentDate <= calendar.startOfDay(for: orderedEndDate) {
                dates.append(currentDate)
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                currentDate = nextDate
            }
            return dates
        }
    }

    // UIViewRepresentable 프로토콜 메서드
    func makeUIView(context: Context) -> FSCalendar {
        let calendar = FSCalendar()
        calendar.delegate = context.coordinator
        calendar.dataSource = context.coordinator

        calendar.scope = .month
        calendar.firstWeekday = 2

        calendar.appearance.headerTitleFont = .systemFont(ofSize: 20, weight: .bold)
        calendar.appearance.weekdayFont = .systemFont(ofSize: 15, weight: .semibold)
        calendar.appearance.titleFont = .systemFont(ofSize: 17)
        calendar.appearance.eventDefaultColor = UIColor.systemGreen
        
        // MARK: 배경색을 투명으로 설정
        calendar.backgroundColor = .clear
        
        calendar.appearance.titleDefaultColor = isDarkMode ? .white : .black
        calendar.appearance.weekdayTextColor = isDarkMode ? .lightGray : .darkGray
        calendar.appearance.headerTitleColor = isDarkMode ? .white : .black
        
        // selectionColor를 고정값으로 설정하지 않음 (fillSelectionColorFor에서 동적으로 처리)
        calendar.appearance.todayColor = UIColor(calendarAccentColor.opacity(0.2))
        calendar.appearance.titleTodayColor = UIColor(calendarAccentColor)
        
        calendar.allowsMultipleSelection = true
        calendar.swipeToChooseGesture.isEnabled = true
        
        return calendar
    }

    func updateUIView(_ uiView: FSCalendar, context: Context) {
        // MARK: 배경색을 투명으로 설정
        uiView.backgroundColor = .clear
        
        uiView.appearance.titleDefaultColor = isDarkMode ? .white : .black
        uiView.appearance.weekdayTextColor = isDarkMode ? .lightGray : .darkGray
        uiView.appearance.headerTitleColor = isDarkMode ? .white : .black
        
        context.coordinator.resolvedAccentColor = calendarAccentColor
        context.coordinator.isDarkMode = isDarkMode

        uiView.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, resolvedAccentColor: calendarAccentColor, isDarkMode: isDarkMode)
    }
}
