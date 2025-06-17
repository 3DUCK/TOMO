// MARK: - MemoEditView.swift
import SwiftUI

struct MemoEditView: View {
    @EnvironmentObject var settings: UserSettings
    @ObservedObject var viewModel: QuoteViewModel
    @Binding var selectedQuote: Quote? // 상위 뷰의 selectedQuoteForMemo와 바인딩
    
    @State private var currentMemo: String
    @State private var currentEmotion: String?
    @State private var showDiscardAlert = false
    
    let emotionOptions = ["😊", "😢", "😠", "😎", "😴", "💡", "✨", "🙂"]
    
    init(selectedQuote: Binding<Quote?>, viewModel: QuoteViewModel) {
        self._selectedQuote = selectedQuote
        self.viewModel = viewModel
        self._currentMemo = State(initialValue: selectedQuote.wrappedValue?.memo ?? "")
        self._currentEmotion = State(initialValue: selectedQuote.wrappedValue?.emotion)
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text(" \(selectedQuote?.text ?? "")")
                    .font(settings.getCustomFont(size: 20))
                    .padding(.horizontal)
                
                Divider()
                
                Text("메모 작성 (최대 500자)")
                    .font(.headline)
                    .padding(.horizontal)
                
                TextEditor(text: $currentMemo)
                    .frame(height: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .font(settings.getCustomFont(size: 16))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: currentMemo) { newValue in
                        if newValue.count > 500 {
                            currentMemo = String(newValue.prefix(500))
                        }
                    }
                
                Text("감정 선택")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(emotionOptions, id: \.self) { emotion in
                            Button(action: {
                                currentEmotion = (currentEmotion == emotion) ? nil : emotion
                            }) {
                                Text(emotion)
                                    .font(.largeTitle)
                                    .padding(8)
                                    .background(currentEmotion == emotion ? Color.accentColor.opacity(0.3) : Color.clear)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("메모 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        if currentMemo != (selectedQuote?.memo ?? "") || currentEmotion != selectedQuote?.emotion {
                            showDiscardAlert = true
                        } else {
                            selectedQuote = nil // 시트 닫기
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        if var quote = selectedQuote {
                            quote.memo = currentMemo
                            quote.emotion = currentEmotion
                            viewModel.updateQuoteMemoAndEmotion(id: quote.id, memo: currentMemo, emotion: currentEmotion)
                            selectedQuote = nil // 시트 닫기
                        }
                    }
                    .disabled(currentMemo.isEmpty && currentEmotion == nil)
                }
            }
            .alert("변경 사항을 저장하지 않겠습니까?", isPresented: $showDiscardAlert) {
                Button("저장하지 않고 닫기", role: .destructive) {
                    selectedQuote = nil // 시트 닫기
                }
                Button("저장") {
                    if var quote = selectedQuote {
                        quote.memo = currentMemo
                        quote.emotion = currentEmotion
                        viewModel.updateQuoteMemoAndEmotion(id: quote.id, memo: currentMemo, emotion: currentEmotion)
                        selectedQuote = nil // 시트 닫기
                    }
                }
                Button("취소", role: .cancel) {}
            }
            .preferredColorScheme(settings.preferredColorScheme)
        }
    }
}
