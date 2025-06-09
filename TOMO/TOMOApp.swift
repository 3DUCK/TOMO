//
//  TOMOApp.swift
//  TOMO
//
//  Created by KG on 6/9/25.
//

import SwiftUI

@main
struct TOMOApp: App {
    @StateObject var settings = UserSettings()
    
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
