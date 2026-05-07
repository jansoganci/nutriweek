//
//  NutriWeekApp.swift
//  NutriWeek
//
//  Created by CanSoganci on 5.05.2026.
//

import SwiftUI

@main
struct NutriWeekApp: App {
    init() {
        FontRegistration.registerInterFonts()
        print("|" + SupabaseConfig.url + "|")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
