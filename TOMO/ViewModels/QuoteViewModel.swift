// QuoteViewModel.swift
import Foundation
import Combine

class QuoteViewModel: ObservableObject {
    @Published var todayQuote: String = "불러오는 중..."

    func loadQuote() {
        QuoteService.shared.fetchTodayQuote { [weak self] quote in
            DispatchQueue.main.async {
                self?.todayQuote = quote
            }
        }
    }
}
