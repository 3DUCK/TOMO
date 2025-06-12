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
        ZStack {
            if let bgImage = backgroundImage {
                Image(uiImage: bgImage)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .opacity(backgroundImageOpacity)
                    .overlay(
                        Rectangle()
                            .fill(settings.preferredColorScheme == .dark ?
                                  Color.black.opacity(0.5) :
                                  Color.white.opacity(0.5)
                                )
                                .edgesIgnoringSafeArea(.all)
                                .opacity(backgroundImageOpacity)
                    )
            } else {
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                    .opacity(backgroundImageOpacity)
            }

            VStack(spacing: 20) {
                Text("오늘의 문구")
                    .font(.headline)
                    .foregroundColor(settings.preferredColorScheme == .dark ? .white : .black)

                Text("\"" + animatedQuote + "\"")
                    .font(settings.fontStyle)
                    .multilineTextAlignment(.center)
                    .padding()
                    .padding(.horizontal, 20)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(settings.preferredColorScheme == .dark ? .white : .black)
            }
        }
        .onAppear {
            //print("TodayQuoteView ➡️ onAppear: View appeared. Calling fetchAndSaveTodayQuote().")
            withAnimation(.easeIn(duration: 2.0)) {
                backgroundImageOpacity = 1.0
            }
            viewModel.fetchAndSaveTodayQuote()
            // ✅ 추가: onAppear 시점에 현재 viewModel.todayQuote 값으로 애니메이션 시작
            //print("TodayQuoteView 🎬 onAppear: Starting animation with current viewModel.todayQuote: \"\(viewModel.todayQuote)\".")
            startTypingAnimation(for: viewModel.todayQuote)
        }
        .onChange(of: viewModel.todayQuote) { newQuote in
            //print("TodayQuoteView 🔄 onChange: viewModel.todayQuote changed to: \"\(newQuote)\".")
            startTypingAnimation(for: newQuote)
        }
        .onDisappear {
            //print("TodayQuoteView ⬅️ onDisappear: View disappeared. Cancelling animation task.")
            quoteAnimationTask?.cancel()
        }
        .preferredColorScheme(settings.preferredColorScheme)
    }

    private func startTypingAnimation(for fullQuote: String) {
        //print("TodayQuoteView 🎬 startTypingAnimation: Attempting to animate quote: \"\(fullQuote)\".")
        quoteAnimationTask?.cancel()
        animatedQuote = ""

        guard !fullQuote.isEmpty else {
            //print("TodayQuoteView ⚠️ startTypingAnimation: fullQuote is empty. Animation skipped.")
            return
        }

        quoteAnimationTask = Task {
            for (index, char) in fullQuote.enumerated() {
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard !Task.isCancelled else {
                    //print("TodayQuoteView 🚫 startTypingAnimation: Task cancelled mid-animation.")
                    return
                }
                animatedQuote += String(char)
            }
            //print("TodayQuoteView ✅ startTypingAnimation: Animation complete. Final animatedQuote: \"\(animatedQuote)\".")
        }
    }
}

