// MARK: - MemoEditView.swift
import SwiftUI

struct MemoEditView: View {
    @EnvironmentObject var settings: UserSettings
    @ObservedObject var viewModel: QuoteViewModel // QuoteViewModel을 주입받아 데이터 업데이트
    @Binding var isShowingSheet: Bool // 시트 닫기 위한 바인딩
    
    @State var quote: Quote // 편집할 Quote를 State로 받아서 변경 가능하게 (초기값으로 사용)
    @State private var currentMemo: String // 현재 메모 내용
    @State private var currentEmotion: String? // 현재 선택된 감정
    
    let emotionOptions = ["😊", "😢", "😠", "😎", "😴", "💡", "✨", "🙂"] // 감정 이모티콘 목록
    
    // 초기화 시점에 전달받은 quote의 메모와 감정으로 State 변수 초기화
    init(quote: Quote, viewModel: QuoteViewModel, isShowingSheet: Binding<Bool>) {
        self.quote = quote
        self.viewModel = viewModel
        self._isShowingSheet = isShowingSheet
        self._currentMemo = State(initialValue: quote.memo ?? "") // 메모가 nil이면 빈 문자열로 초기화
        self._currentEmotion = State(initialValue: quote.emotion) // 감정이 nil이면 nil로 초기화
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text(" \(quote.text)")
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
                    .font(settings.getCustomFont(size: 16)) // 메모 입력 폰트
                    .autocapitalization(.none) // 자동 대문자 방지 (선택 사항)
                    .disableAutocorrection(true) // 자동 수정 방지 (선택 사항)
                    .onChange(of: currentMemo) { newValue in
                        if newValue.count > 500 {
                            currentMemo = String(newValue.prefix(500)) // 500자 제한
                        }
                    }
                
                Text("감정 선택")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(emotionOptions, id: \.self) { emotion in
                            Button(action: {
                                // 현재 선택된 감정과 동일하면 선택 해제, 아니면 선택
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
                        isShowingSheet = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        // QuoteViewModel의 함수 호출하여 메모 및 감정 업데이트
                        viewModel.updateQuoteMemoAndEmotion(id: quote.id, memo: currentMemo, emotion: currentEmotion)
                        isShowingSheet = false
                    }
                }
            }
            .preferredColorScheme(settings.preferredColorScheme)
        }
    }
}
