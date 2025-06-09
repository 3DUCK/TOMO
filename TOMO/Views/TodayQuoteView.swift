// MARK: - TodayQuoteView.swift (폰트/테마 적용)
import SwiftUI

struct TodayQuoteView: View {
    @EnvironmentObject var settings: UserSettings

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("오늘의 문구")
                    .font(.headline)

                Text("성공은 작은 노력이 쌓인 결과입니다.")
                    .font(settings.fontStyle)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .preferredColorScheme(settings.preferredColorScheme)
    }
}
