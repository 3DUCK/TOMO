//
//  QuoteViewModel.swift
//  TOMO
//
//  Created by KG on 6/9/25.
//
import Foundation

class QuoteViewModel: ObservableObject {
    @Published var quote: Quote = Quote(id: UUID().uuidString, text: "오늘도 파이팅입니다!", date: Date())
    
    // 추후 Firebase에서 가져오는 메서드 추가 예정
    func fetchTodayQuote() {
        // 서버에서 오늘 날짜에 맞는 quote를 불러오는 코드 작성 예정
    }
}
