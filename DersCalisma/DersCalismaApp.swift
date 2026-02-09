//
//  DersCalismaApp.swift
//  DersCalisma
//
//  Created by Yunus Terzi on 31.01.2026.
//

import SwiftUI
import SwiftData

@main
struct DersCalismaApp: App {
    var body: some Scene {
        WindowGroup {
            // Uygulama açıldığında kullanıcıyı karşılayacak alt menülü yapı
            TabView {
                NavigationStack {
                    TimerView()
                }
                .tabItem {
                    Label("Sayaç", systemImage: "timer")
                }
                
                NavigationStack {
                    ProfileView()
                }
                .tabItem {
                    Label("Profilim", systemImage: "person.fill")
                }
            }
            // "Cozy" bir hava için tüm uygulamada turuncu/pastel tonlar
            .accentColor(.orange)
        }
        // Veritabanını (SwiftData) tüm uygulama için aktif eder
        .modelContainer(for: [FocusSession.self, UserSettings.self])
    }
}
