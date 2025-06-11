// MARK: - TodayQuoteView.swift
import SwiftUI
import UIKit // UIImage를 사용하기 위해 필요

struct TodayQuoteView: View {
    @EnvironmentObject var settings: UserSettings
    @StateObject var viewModel = QuoteViewModel()

    // 배경 이미지 페이드인 애니메이션을 위한 State 변수
    @State private var backgroundImageOpacity: Double = 0.0

    // 오늘의 문구 타이핑 애니메이션을 위한 State 변수
    @State private var animatedQuote: String = ""
    @State private var quoteAnimationTask: Task<Void, Never>? = nil // 애니메이션 Task를 저장하여 취소 가능하게 함

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
            if let bgImage = backgroundImage {
                Image(uiImage: bgImage)
                    .resizable()
                    .scaledToFill() // 화면을 꽉 채우도록
                    .edgesIgnoringSafeArea(.all) // 화면 전체를 덮도록
                    .opacity(backgroundImageOpacity) // <-- 페이드인 효과 적용
                    // 테마에 따라 밝기 조절을 위한 오버레이 추가
                    .overlay(
                        Rectangle()
                            .fill(settings.preferredColorScheme == .dark ?
                                  Color.black.opacity(0.5) : // 다크 모드일 때 어둡게
                                  Color.white.opacity(0.5)  // 라이트 모드일 때 밝게 (텍스트 잘 보이도록)
                            )
                            .edgesIgnoringSafeArea(.all)
                            .opacity(backgroundImageOpacity) // <-- 오버레이도 이미지와 함께 페이드인
                    )
            } else {
                // 배경 이미지가 없을 경우 기본 배경색 유지
                Color(.systemBackground) // 혹은 원하는 다른 배경색
                    .edgesIgnoringSafeArea(.all)
                    .opacity(backgroundImageOpacity) // <-- 배경색도 페이드인 (선택 사항)
            }

            VStack(spacing: 20) {
                Text("오늘의 문구")
                    .font(.headline)
                    .foregroundColor(settings.preferredColorScheme == .dark ? .white : .black) // 테마에 따라 텍스트 색상 조절

                Text(animatedQuote) // <-- 애니메이션될 문구 사용
                    .font(settings.fontStyle)
                    .multilineTextAlignment(.center)
                    .padding()
                    .padding(.horizontal, 20) // 좌우 패딩을 줘서 텍스트가 화면 끝에 붙지 않도록
                    .lineSpacing(5) // <-- 여기에서 줄 간격 조절 (예시: 5pt 추가 간격)
                    .frame(maxWidth: .infinity) // <-- 텍스트가 가로로 최대한 확장되도록 (padding 고려)
                    .foregroundColor(settings.preferredColorScheme == .dark ? .white : .black) // 테마에 따라 텍스트 색상 조절
            }
        }
        .onAppear {
            // 뷰가 나타날 때 배경 페이드인만 시작
            withAnimation(.easeIn(duration: 2.0)) { // 1초 동안 천천히 나타나도록
                backgroundImageOpacity = 1.0
            }
            // onAppear 시점에 loadQuote를 호출하여 문구 로드 시작
            viewModel.loadQuote()
        }
        // viewModel.todayQuote 값이 변경될 때마다 애니메이션을 시작하도록 watch
        .onChange(of: viewModel.todayQuote) { newQuote in // <-- 이 부분 추가
            // 새로운 문구가 로드되었을 때 타이핑 애니메이션 시작
            startTypingAnimation(for: newQuote)
        }
        .onDisappear {
            // 뷰가 사라질 때 애니메이션 Task 취소
            quoteAnimationTask?.cancel()
        }
        .preferredColorScheme(settings.preferredColorScheme)
    }

    // 타이핑 애니메이션을 시작하는 별도의 함수
    private func startTypingAnimation(for fullQuote: String) {
        quoteAnimationTask?.cancel() // 기존 애니메이션이 있다면 취소
        animatedQuote = "" // 애니메이션 시작 전 초기화

        // 비동기 Task로 타이핑 애니메이션 실행
        quoteAnimationTask = Task {
            for (index, char) in fullQuote.enumerated() {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.05초 (50ms) 딜레이
                guard !Task.isCancelled else { return } // Task가 취소되었으면 중단
                animatedQuote += String(char)
            }
        }
    }
}
