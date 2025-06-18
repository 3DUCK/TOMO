// MARK: - TodayQuoteView.swift
import SwiftUI
import UIKit

struct TodayQuoteView: View {
    @EnvironmentObject var settings: UserSettings
    @StateObject var viewModel = QuoteViewModel()

    @State private var backgroundImageOpacity: Double = 0.0
    @State private var animatedQuote: String = ""
    @State private var quoteAnimationTask: Task<Void, Never>? = nil

    var backgroundImage: UIImage? {
        if let data = settings.backgroundImageData {
            return UIImage(data: data)
        }
        return nil
    }

    var body: some View {
        GeometryReader { geometry in // GeometryReader를 사용하여 전체 화면 크기를 측정
            ZStack {
                // MARK: - 배경 이미지 레이어
                if let bgImage = backgroundImage {
                    Image(uiImage: bgImage)
                        .resizable()
                        .scaledToFill()
                        // GeometryReader가 측정한 전체 화면 크기에 맞추고 클리핑
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped() // 프레임을 벗어나는 부분은 잘라냅니다.
                        .opacity(backgroundImageOpacity)
                        .overlay(
                            Rectangle()
                                .fill(settings.preferredColorScheme == .dark ?
                                      Color.black.opacity(0.5) :
                                      Color.white.opacity(0.5)
                                     )
                                // 오버레이도 전체 화면 크기에 맞춥니다.
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .opacity(backgroundImageOpacity)
                        )
                } else {
                    Color(.systemBackground)
                        // 배경색도 전체 화면 크기에 맞춥니다.
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .opacity(backgroundImageOpacity)
                }

                // MARK: - 전경 콘텐츠 레이어 (오늘의 문구)
                VStack(spacing: 20) {
                    Spacer() // 상단 여백을 채워 내용을 세로 중앙으로 보냅니다.
                    Text("오늘의 문구")
                        .font(.headline)
                        .foregroundColor(settings.preferredColorScheme == .dark ? .white : .black)
                    Text("\"" + animatedQuote + "\"")
                        .font(settings.fontStyle)
                        .multilineTextAlignment(.center)
                        .padding()
                        .padding(.horizontal, 20) // 좌우 패딩을 유지하여 텍스트가 너무 가장자리에 붙지 않도록 합니다.
                        .lineSpacing(5)
                        .foregroundColor(settings.preferredColorScheme == .dark ? .white : .black)
                    Spacer() // 하단 여백을 채워 내용을 세로 중앙으로 보냅니다.
                }
                // VStack이 GeometryReader가 제공하는 모든 공간을 차지하도록 합니다.
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            // ZStack에는 더 이상 .edgesIgnoringSafeArea(.all)을 적용하지 않습니다.
            // 대신 GeometryReader 자체에 적용할 것입니다.
        }
        .ignoresSafeArea(.all) // <-- **여기!**: GeometryReader 자체가 안전 영역을 무시하도록 설정 (iOS 14 이상 권장)
        // 만약 iOS 13 호환이 필요하다면 아래 줄을 사용하세요:
        // .edgesIgnoringSafeArea(.all)
        .onAppear {
            withAnimation(.easeIn(duration: 2.0)) {
                backgroundImageOpacity = 1.0
            }
            viewModel.fetchAndSaveTodayQuote(goal: settings.goal)
            startTypingAnimation(for: viewModel.todayQuote)
        }
        .onChange(of: settings.goal) { newGoal in
            viewModel.fetchAndSaveTodayQuote(goal: newGoal)
        }
        .onChange(of: viewModel.todayQuote) { newQuote in
            startTypingAnimation(for: newQuote)
        }
        .onDisappear {
            quoteAnimationTask?.cancel()
        }
        .preferredColorScheme(settings.preferredColorScheme)
    }

    private func startTypingAnimation(for fullQuote: String) {
        quoteAnimationTask?.cancel()
        animatedQuote = ""

        guard !fullQuote.isEmpty else {
            return
        }

        quoteAnimationTask = Task {
            for (index, char) in fullQuote.enumerated() {
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard !Task.isCancelled else {
                    return
                }
                animatedQuote += String(char)
            }
        }
    }
}
