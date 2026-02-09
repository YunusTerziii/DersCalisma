//
//  ProfileView.swift
//  DersCalisma
//
//  Created by Yunus Terzi on 31.01.2026.
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Model for Chart
struct WeeklyReport: Identifiable {
    let id = UUID()
    let day: String
    let minutes: Int
}

// MARK: - Main View
struct ProfileView: View {
    @State private var selectedTab: Int = 47 // En son hafta (Bu Hafta) seçili başlasın
    @Query(sort: \FocusSession.date, order: .reverse) private var sessions: [FocusSession]
    
    var totalPoints: Int {
        sessions.reduce(0) { $0 + $1.pointsEarned }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 1. Grafik Bölümü (Kaydırılabilir)
                Section("İstatistikler") {
                    VStack {
                        TabView(selection: $selectedTab) {
                            ForEach(0..<weeklyBundles.count, id: \.self) { index in
                                VStack(alignment: .leading, spacing: 10) {
                                    // Başlık: 47. indeks "Bu Hafta", diğerleri tarih aralığı
                                    Text(index == 47 ? "Bu Hafta" : weekRangeString(for: 47 - index))
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                    
                                    Chart {
                                        ForEach(weeklyBundles[index]) { data in
                                            BarMark(
                                                x: .value("Gün", data.day),
                                                y: .value("Dakika", data.minutes)
                                            )
                                            .foregroundStyle(Color.orange.gradient)
                                            .cornerRadius(5)
                                        }
                                    }
                                }
                                .tag(index)
                                .padding(.bottom, 30)
                            }
                        }
                        .frame(height: 280)
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                }
                
                // 2. Toplam Puan Bölümü
                Section {
                    HStack {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(.orange)
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text("Toplam Puanın")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(totalPoints) Puan")
                                .font(.title2.bold())
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Profilim")
        }
    }
}

// MARK: - Logic Extension
extension ProfileView {
    var weeklyBundles: [[WeeklyReport]] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 1: Pazar, 2: Pazartesi. Haftayı Pazartesi'den başlatıyoruz.
        
        var bundles: [[WeeklyReport]] = []
        let today = Date()
        
        // Mevcut haftanın Pazartesi gününü bulalım
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        guard let startOfCurrentWeek = calendar.date(from: components) else { return [] }
        
        for weekOffset in (0..<48).reversed() {
            var weekData: [WeeklyReport] = []
            
            // Seçili haftanın başlangıç gününü (Pazartesi) bul
            let startOfSelectedWeek = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: startOfCurrentWeek)!
            
            for dayOffset in 0..<7 {
                // Pazartesi'den başlayarak 7 günü ekle
                let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfSelectedWeek)!
                let dayName = date.formatted(.dateTime.weekday(.abbreviated))
                
                let totalMinutes = sessions.filter { calendar.isDate($0.date, inSameDayAs: date) }
                    .reduce(0) { $0 + $1.durationMinutes }
                
                weekData.append(WeeklyReport(day: dayName, minutes: totalMinutes))
            }
            bundles.append(weekData)
        }
        return bundles
    }

    func weekRangeString(for weekOffset: Int) -> String {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        let startOfCurrentWeek = calendar.date(from: components)!
        
        // İlgili haftanın başlangıcı (Pazartesi) ve bitişi (Pazar)
        let startOfSelectedWeek = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: startOfCurrentWeek)!
        let endOfSelectedWeek = calendar.date(byAdding: .day, value: 6, to: startOfSelectedWeek)!
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM"
        
        return "\(formatter.string(from: startOfSelectedWeek)) - \(formatter.string(from: endOfSelectedWeek))"
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
        .modelContainer(for: FocusSession.self, inMemory: true)
}
