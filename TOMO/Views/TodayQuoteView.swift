// MARK: - TodayQuoteView.swift
import SwiftUI
import UIKit // UIImage를 사용하기 위해 필요

struct TodayQuoteView: View {
    @EnvironmentObject var settings: UserSettings
    @StateObject var viewModel = QuoteViewModel()

    // 배경 이미지 데이터를 UIImage로 변환하는 연산 프로퍼티
    var backgroundImage: UIImage? {
        if let data = settings.backgroundImageData {
            return UIImage(data: data)
        }
        return nil
    }

    var body: some View {
        ZStack {
            // 배경 이미지가 있을 경우 표시
            // backgroundType을 사용하지 않고 직접 backgroundImage 유무로 판단
            if let bgImage = backgroundImage {
                Image(uiImage: bgImage)
                    .resizable()
                    .scaledToFill() // 화면을 꽉 채우도록
                    .edgesIgnoringSafeArea(.all) // 화면 전체를 덮도록
                    // 테마에 따라 밝기 조절을 위한 오버레이 추가
                    .overlay(
                        Rectangle()
                            .fill(settings.preferredColorScheme == .dark ?
                                  Color.black.opacity(0.5) : // 다크 모드일 때 어둡게
                                  Color.white.opacity(0.5)  // 라이트 모드일 때 밝게 (텍스트 잘 보이도록)
                            )
                            .edgesIgnoringSafeArea(.all)
                    )
            } else {
                // 배경 이미지가 없을 경우 기본 배경색 유지
                Color(.systemBackground) // 혹은 원하는 다른 배경색
                    .edgesIgnoringSafeArea(.all)
            }

            VStack(spacing: 20) {
                Text("오늘의 문구")
                    .font(.headline)
                    .foregroundColor(settings.preferredColorScheme == .dark ? .white : .black) // 테마에 따라 텍스트 색상 조절

                Text(viewModel.todayQuote)
                    .font(settings.fontStyle)
                    .multilineTextAlignment(.center)
                    .padding()
                    .foregroundColor(settings.preferredColorScheme == .dark ? .white : .black) // 테마에 따라 텍스트 색상 조절
            }
        }
        .onAppear {
            viewModel.loadQuote()
        }
        .preferredColorScheme(settings.preferredColorScheme)
    }
}
