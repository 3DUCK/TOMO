//
//  Quote.swift
//  TOMO
//
//  Created by KG on 6/9/25.
//

import Foundation

struct Quote: Identifiable, Codable {
    let id: String
    let text: String
    let date: Date
}
