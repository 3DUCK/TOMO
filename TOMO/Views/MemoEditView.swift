//
// MemoEditView.swift
//
// 이 파일은 사용자가 특정 문구(`Quote`)에 대한 메모와 감정 태그를 편집할 수 있도록 팝업되는 시트 뷰를 정의합니다.
//
// 주요 기능:
// - 선택된 문구의 내용을 표시합니다.
// - 텍스트 필드를 통해 메모를 작성하거나 수정할 수 있습니다 (최대 500자 제한).
// - 미리 정의된 이모티콘 중에서 문구에 대한 감정을 선택하거나 해제할 수 있습니다.
// - 변경 사항을 저장하거나, 저장하지 않고 닫을 경우 경고 알림을 통해 사용자에게 확인을 요청합니다.
// - `UserSettings`와 `QuoteViewModel`을 활용하여 데이터 관리 및 UI 사용자 정의를 지원합니다.
//

import SwiftUI

/// 문구에 대한 메모와 감정을 편집하는 시트 뷰.
/// 상위 뷰에서 `selectedQuote`를 바인딩하여 표시됩니다.
struct MemoEditView: View {
    /// 사용자 설정(폰트, 테마 등)을 관리하는 환경 객체.
    @EnvironmentObject var settings: UserSettings
    /// 문구 데이터와 로직을 관리하는 `QuoteViewModel` 인스턴스.
    @ObservedObject var viewModel: QuoteViewModel
    /// 편집할 `Quote` 객체에 대한 바인딩. `nil`이 되면 시트가 닫힙니다.
    @Binding var selectedQuote: Quote?
    
    /// 현재 편집 중인 메모 내용을 저장하는 상태 변수.
    @State private var currentMemo: String
    /// 현재 선택된 감정 이모티콘을 저장하는 상태 변수.
    @State private var currentEmotion: String?
    /// 변경 사항을 저장하지 않고 닫으려 할 때 알림을 표시할지 여부를 결정하는 상태 변수.
    @State private var showDiscardAlert = false
    
    /// 사용자가 선택할 수 있는 감정 이모티콘 옵션.
    let emotionOptions = ["😊", "😢", "😠", "😎", "😴", "💡", "✨", "🙂"]
    
    // MARK: - Initialization
    
    /// `MemoEditView` 초기화 메서드.
    /// - Parameters:
    ///   - selectedQuote: 편집할 `Quote` 객체에 대한 바인딩.
    ///   - viewModel: `QuoteViewModel` 인스턴스.
    init(selectedQuote: Binding<Quote?>, viewModel: QuoteViewModel) {
        self._selectedQuote = selectedQuote
        self.viewModel = viewModel
        // 초기화 시 선택된 문구의 기존 메모와 감정으로 상태 변수를 설정합니다.
        self._currentMemo = State(initialValue: selectedQuote.wrappedValue?.memo ?? "")
        self._currentEmotion = State(initialValue: selectedQuote.wrappedValue?.emotion)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // 편집 중인 문구의 텍스트 표시
                Text(" \(selectedQuote?.text ?? "")")
                    .font(settings.getCustomFont(size: 20))
                    .padding(.horizontal)
                
                Divider() // 문구와 메모 섹션 구분선
                
                // 메모 작성 제목
                Text("메모 작성 (최대 500자)")
                    .font(.headline)
                    .padding(.horizontal)
                
                // 메모 입력 TextEditor
                TextEditor(text: $currentMemo)
                    .frame(height: 150) // 높이 고정
                    .overlay(
                        // 테두리 추가
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .font(settings.getCustomFont(size: 16))
                    .autocapitalization(.none) // 자동 대문자화 비활성화
                    .disableAutocorrection(true) // 자동 수정 비활성화
                    .onChange(of: currentMemo) { newValue, _ in // iOS 17+ onChange
                        // 메모 길이 500자 제한
                        if newValue.count > 500 {
                            currentMemo = String(newValue.prefix(500))
                        }
                    }
                
                // 감정 선택 제목
                Text("감정 선택")
                    .font(.headline)
                    .padding(.horizontal)
                
                // 감정 이모티콘 선택 스크롤 뷰
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(emotionOptions, id: \.self) { emotion in
                            Button(action: {
                                // 현재 선택된 감정과 동일하면 해제, 아니면 선택
                                currentEmotion = (currentEmotion == emotion) ? nil : emotion
                            }) {
                                Text(emotion)
                                    .font(.largeTitle)
                                    .padding(8)
                                    .background(currentEmotion == emotion ? Color.accentColor.opacity(0.3) : Color.clear) // 선택 시 배경색 변경
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer() // 남은 공간 채우기
            }
            .navigationTitle("메모 편집") // 내비게이션 바 제목
            .navigationBarTitleDisplayMode(.inline) // 제목을 인라인으로 표시
            .toolbar {
                // 좌측 취소 버튼
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        // 현재 메모나 감정이 원본과 다르면 변경 사항 버릴지 확인
                        if currentMemo != (selectedQuote?.memo ?? "") || currentEmotion != selectedQuote?.emotion {
                            showDiscardAlert = true
                        } else {
                            selectedQuote = nil // 변경 사항 없으면 바로 시트 닫기
                        }
                    }
                }
                // 우측 저장 버튼
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        // 선택된 문구가 유효할 때만 저장 로직 수행
                        if let quote = selectedQuote {
                            // `viewModel`을 통해 메모와 감정 업데이트
                            viewModel.updateQuoteMemoAndEmotion(id: quote.id, memo: currentMemo, emotion: currentEmotion)
                            selectedQuote = nil // 시트 닫기
                        }
                    }
                    // 메모가 비어있고 감정도 선택되지 않았다면 저장 버튼 비활성화
                    .disabled(currentMemo.isEmpty && currentEmotion == nil)
                }
            }
            // 변경 사항 버리기 확인 알림
            .alert("변경 사항을 저장하지 않겠습니까?", isPresented: $showDiscardAlert) {
                Button("저장하지 않고 닫기", role: .destructive) {
                    selectedQuote = nil // 시트 닫기
                }
                Button("저장") {
                    if let quote = selectedQuote {
                        viewModel.updateQuoteMemoAndEmotion(id: quote.id, memo: currentMemo, emotion: currentEmotion)
                        selectedQuote = nil // 시트 닫기
                    }
                }
                Button("취소", role: .cancel) {} // 알림 유지
            }
            // 사용자 설정에 따른 색상 스킴 적용
            .preferredColorScheme(settings.preferredColorScheme)
        }
    }
}
