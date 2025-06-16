//
//  TOMOApp.swift
//  TOMO
//
//  Created by KG on 6/9/25.
//

import SwiftUI
import FirebaseCore

@main
struct TOMOApp: App {
    @StateObject var settings = UserSettings()
    
    // Firebase 초기화 코드 추가
    init() {
        FirebaseApp.configure() // <-- 여기에 Firebase 초기화 코드를 추가
        print("FirebaseApp configured.") //ㅇㄴㅁㅇㄴㅁ
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(settings)
        }
    }
}

#Preview {
    MainTabView()
}
