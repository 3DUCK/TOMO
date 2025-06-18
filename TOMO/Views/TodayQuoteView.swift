//
// TodayQuoteView.swift
//
// 이 파일은 앱의 '오늘의 문구' 탭에 해당하는 뷰를 정의합니다.
// 사용자가 설정한 목표(`UserSettings`)에 맞춰 매일 새로운 문구를 표시하며,
// 배경 이미지를 설정할 경우 해당 이미지를 블러 처리하여 배경으로 사용하고,
// 문구가 한 글자씩 타이핑되는 애니메이션 효과를 제공합니다.
//
// 주요 기능:
// - `UserSettings`로부터 배경 이미지, 폰트, 테마 설정을 가져와 UI에 적용합니다.
// - `QuoteViewModel`을 통해 오늘의 문구를 가져오고 관리합니다.
// - 배경 이미지가 있을 경우 이미지를 배경으로 표시하고, 없으면 시스템 기본 배경색을 사용합니다.
// - 문구가 화면에 나타날 때 부드럽게 페이드인되는 애니메이션 효과를 적용합니다.
// - 오늘의 문구가 글자 단위로 타이핑되는 애니메이션을 구현하여 시각적인 재미를 더합니다.
//

import SwiftUI
import UIKit // UIImage를 사용하기 위해 필요

/// 앱의 '오늘의 문구'를 표시하는 뷰.
/// 사용자 설정에 따라 배경 이미지, 폰트, 테마를 적용하고, 문구에 타이핑 애니메이션을 제공합니다.
struct TodayQuoteView: View {
    /// 사용자 설정(배경 이미지, 폰트, 테마 등)을 관리하는 환경 객체.
    @EnvironmentObject var settings: UserSettings
    /// 문구 데이터와 로직을 관리하는 `QuoteViewModel` 인스턴스.
    @StateObject var viewModel = QuoteViewModel()

    /// 배경 이미지의 투명도를 제어하는 상태 변수 (페이드인 애니메이션에 사용).
    @State private var backgroundImageOpacity: Double = 0.0
    /// 타이핑 애니메이션을 위해 현재 표시되는 문구의 일부분을 저장하는 상태 변수.
    @State private var animatedQuote: String = ""
    /// 문구 타이핑 애니메이션을 실행하는 `Task`에 대한 참조. 취소에 사용됩니다.
    @State private var quoteAnimationTask: Task<Void, Never>? = nil

    /// `UserSettings`에 저장된 배경 이미지 데이터(`Data`)를 `UIImage`로 변환하여 반환합니다.
    /// 이미지가 없으면 `nil`을 반환합니다.
    var backgroundImage: UIImage? {
        if let data = settings.backgroundImageData {
            return UIImage(data: data)
        }
        return nil
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in // GeometryReader를 사용하여 부모 뷰의 전체 크기를 측정합니다.
            ZStack {
                // MARK: - 배경 이미지 레이어
                if let bgImage = backgroundImage {
                    Image(uiImage: bgImage)
                        .resizable()
                        .scaledToFill() // 이미지를 프레임에 꽉 채우도록 스케일
                        // GeometryReader가 측정한 전체 화면 크기에 맞추고 클리핑
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped() // 프레임을 벗어나는 부분은 잘라냅니다.
                        .opacity(backgroundImageOpacity) // 페이드인 애니메이션을 위해 투명도 적용
                        .overlay(
                            // 테마에 따라 오버레이 색상 및 투명도 조절
                            Rectangle()
                                .fill(settings.preferredColorScheme == .dark ?
                                      Color.black.opacity(0.5) : // 다크 모드일 때 어둡게
                                      Color.white.opacity(0.5)    // 라이트 모드일 때 밝게
                                )
                                // 오버레이도 전체 화면 크기에 맞춥니다.
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .opacity(backgroundImageOpacity) // 배경 이미지와 동일한 투명도 적용
                        )
                } else {
                    // 배경 이미지가 없을 경우 시스템 기본 배경색 사용
                    Color(.systemBackground)
                        // 배경색도 전체 화면 크기에 맞춥니다.
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .opacity(backgroundImageOpacity) // 페이드인 애니메이션을 위해 투명도 적용
                }

                // MARK: - 전경 콘텐츠 레이어 (오늘의 문구 및 기타 UI)
                VStack(spacing: 20) {
                    Spacer() // 상단 여백을 채워 내용을 세로 중앙으로 보냅니다.
                    
                    Text("오늘의 문구")
                        .font(.headline)
                        .foregroundColor(settings.preferredColorScheme == .dark ? .white : .black)
                    
                    Text("\"" + animatedQuote + "\"") // 타이핑 애니메이션이 적용된 문구
                        .font(settings.fontStyle) // 사용자 설정 폰트 적용
                        .multilineTextAlignment(.center) // 여러 줄 텍스트 중앙 정렬
                        .padding()
                        .padding(.horizontal, 20) // 좌우 패딩을 유지하여 텍스트가 너무 가장자리에 붙지 않도록 합니다.
                        .lineSpacing(5) // 줄 간격 설정
                        .foregroundColor(settings.preferredColorScheme == .dark ? .white : .black)
                    
                    Spacer() // 하단 여백을 채워 내용을 세로 중앙으로 보냅니다.
                }
                // VStack이 GeometryReader가 제공하는 모든 공간을 차지하도록 합니다.
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea(.all) // GeometryReader 자체가 모든 안전 영역을 무시하도록 설정 (iOS 14 이상 권장)
        // 만약 iOS 13 호환이 필요하다면 아래 줄을 사용하세요:
        // .edgesIgnoringSafeArea(.all)
        .onAppear {
            // 뷰가 나타날 때 배경 이미지 페이드인 애니메이션 시작
            withAnimation(.easeIn(duration: 2.0)) {
                backgroundImageOpacity = 1.0
            }
            // 오늘의 문구 가져오기 및 저장
            viewModel.fetchAndSaveTodayQuote(goal: settings.goal)
            // 가져온 문구로 타이핑 애니메이션 시작
            startTypingAnimation(for: viewModel.todayQuote)
            print("TodayQuoteView ➡️ onAppear: Initial fetch and animation started.")
        }
        .onChange(of: settings.goal) { oldGoal, newGoal in // iOS 17+ onChange
            // 목표가 변경될 때 새로운 문구 가져오기
            print("TodayQuoteView 🔄 onChange: Goal changed from \(oldGoal) to \(newGoal). Fetching new quote.")
            viewModel.fetchAndSaveTodayQuote(goal: newGoal)
        }
        .onChange(of: viewModel.todayQuote) { oldQuote, newQuote in // iOS 17+ onChange
            // 오늘의 문구가 변경될 때마다 타이핑 애니메이션 다시 시작
            print("TodayQuoteView 🔄 onChange: Quote changed. Restarting animation for: \(newQuote)")
            startTypingAnimation(for: newQuote)
        }
        .onDisappear {
            // 뷰가 사라질 때 진행 중인 타이핑 애니메이션 작업을 취소
            quoteAnimationTask?.cancel()
            print("TodayQuoteView ⬅️ onDisappear: Quote animation task cancelled.")
        }
        .preferredColorScheme(settings.preferredColorScheme) // 사용자 설정에 따른 다크/라이트 모드 적용
    }

    // MARK: - Helper Functions

    /// 주어진 전체 문구에 대해 타이핑 애니메이션을 시작합니다.
    /// 기존 애니메이션이 있다면 취소하고 새 애니메이션을 시작합니다.
    /// - Parameter fullQuote: 타이핑 애니메이션을 적용할 전체 문구.
    private func startTypingAnimation(for fullQuote: String) {
        quoteAnimationTask?.cancel() // 기존 애니메이션 작업 취소
        animatedQuote = "" // 현재 표시되는 문구를 초기화

        guard !fullQuote.isEmpty else {
            print("TodayQuoteView ⚠️ No quote to animate.")
            return
        }

        // 새 타이핑 애니메이션 작업 시작
        quoteAnimationTask = Task {
            for (index, char) in fullQuote.enumerated() {
                // 0.1초(1억 나노초)마다 한 글자씩 추가
                try? await Task.sleep(nanoseconds: 100_000_000)
                // 작업이 취소되었는지 확인 (뷰가 사라지는 경우 등)
                guard !Task.isCancelled else {
                    print("TodayQuoteView 🚫 Typing animation cancelled.")
                    return
                }
                // 메인 스레드에서 UI 업데이트
                DispatchQueue.main.async {
                    animatedQuote += String(char)
                }
            }
            print("TodayQuoteView ✅ Typing animation completed.")
        }
    }
}
