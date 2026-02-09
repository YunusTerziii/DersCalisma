import SwiftUI
import SwiftData
import Charts

// MARK: - Model for Chart
struct WeeklyReport: Identifiable, Equatable {
    let id = UUID()
    let day: String
    let minutes: Int
    let date: Date
}

// MARK: - Main View
struct ProfileView: View {
    @State private var selectedTab: Int = 47
    @State private var selectedDayName: String? = nil
    
    // YENİ: Hangi günün detayına bakılacağını tutan değişken
    @State private var selectedReportForDetail: WeeklyReport? = nil
    
    @Query(sort: \FocusSession.date, order: .reverse) private var sessions: [FocusSession]
    
    var totalPoints: Int {
        sessions.reduce(0) { $0 + $1.pointsEarned }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 1. İnteraktif Grafik Bölümü
                Section("İstatistikler") {
                    VStack {
                        TabView(selection: $selectedTab) {
                            ForEach(0..<weeklyBundles.count, id: \.self) { index in
                                VStack(alignment: .leading, spacing: 15) {
                                    
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
                                            .cornerRadius(6)
                                            .opacity(selectedDayName == nil || selectedDayName == data.day ? 1.0 : 0.4)
                                        }
                                        
                                        if let selectedDayName,
                                           let selectedData = weeklyBundles[index].first(where: { $0.day == selectedDayName }) {
                                            RuleMark(x: .value("Gün", selectedDayName))
                                                .foregroundStyle(.gray.opacity(0.2))
                                                .annotation(position: .top, spacing: 5) {
                                                    VStack {
                                                        Text("\(selectedData.minutes) dk")
                                                            .font(.caption.bold())
                                                            .foregroundColor(.white)
                                                            .padding(6)
                                                            .background(Color.brown.cornerRadius(8))
                                                        
                                                        // 👈 YENİ: Kullanıcıyı tıklamaya teşvik eden ufak bir ok
                                                        Image(systemName: "chevron.down")
                                                            .font(.caption2)
                                                            .foregroundColor(.brown)
                                                    }
                                                    // 👈 YENİ: Baloncuğa tıklayınca da açılsın
                                                    .onTapGesture {
                                                        selectedReportForDetail = selectedData
                                                    }
                                                }
                                        }
                                    }
                                    .frame(height: 220)
                                    // Sürükleme ile seçim
                                    .chartXSelection(value: $selectedDayName)
                                    // 👈 YENİ: Çubuğa tek tıklama ile seçim
                                    .chartGesture { proxy in
                                        SpatialTapGesture()
                                            .onEnded { value in
                                                // Tıklanan yerdeki X değerini bul (Gün ismi)
                                                if let dayName = proxy.value(atX: value.location.x, as: String.self) {
                                                    // O güne ait veriyi bul
                                                    if let report = weeklyBundles[index].first(where: { $0.day == dayName }) {
                                                        selectedReportForDetail = report
                                                    }
                                                }
                                            }
                                    }
                                }
                                .tag(index)
                                .padding(.bottom, 30)
                            }
                        }
                        .frame(height: 320)
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                }
                
                // 2. Toplam Puan Kartı
                Section {
                    HStack {
                        ZStack {
                            Circle().fill(Color.orange.opacity(0.1)).frame(width: 50, height: 50)
                            Image(systemName: "star.circle.fill")
                                .foregroundColor(.orange)
                                .font(.title)
                        }
                        VStack(alignment: .leading) {
                            Text("Toplam Puanın").font(.caption).foregroundColor(.secondary)
                            Text("\(totalPoints) Puan").font(.title3.bold())
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // 3. Geçmiş Liste
                Section("Geçmiş Çalışmalar") {
                    if sessions.isEmpty {
                        Text("Henüz bir veri yok.").foregroundColor(.secondary)
                    } else {
                        ForEach(sessions.prefix(5)) { session in // Sadece son 5 taneyi gösterelim, liste çok uzamasın
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green.opacity(0.6))
                                VStack(alignment: .leading) {
                                    Text(session.activity?.name ?? "Genel")
                                        .fontWeight(.medium)
                                    Text("\(session.durationMinutes) dk")
                                        .font(.caption)
                                }
                                Spacer()
                                Text(session.date.formatted(.dateTime.day().month()))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Gelişimim")
            // 👈 YENİ: Sheet burada tetikleniyor
            .sheet(item: $selectedReportForDetail) { report in
                DayDetailView(date: report.date)
                    .presentationDetents([.medium, .large]) // Yarım ekran açılsın
            }
        }
    }
}

// MARK: - Logic Extension
extension ProfileView {
    var weeklyBundles: [[WeeklyReport]] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Pazartesi
        
        var bundles: [[WeeklyReport]] = []
        let today = Date()
        
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        guard let startOfCurrentWeek = calendar.date(from: components) else { return [] }
        
        for weekOffset in (0..<48).reversed() {
            var weekData: [WeeklyReport] = []
            let startOfSelectedWeek = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: startOfCurrentWeek)!
            
            for dayOffset in 0..<7 {
                let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfSelectedWeek)!
                let dayName = date.formatted(.dateTime.weekday(.abbreviated))
                
                let totalMinutes = sessions.filter { calendar.isDate($0.date, inSameDayAs: date) }
                    .reduce(0) { $0 + $1.durationMinutes }
                
                weekData.append(WeeklyReport(day: dayName, minutes: totalMinutes, date: date))
            }
            bundles.append(weekData)
        }
        return bundles
    }
    
    // Helper function (Değişmedi)
    func weekRangeString(for weekOffset: Int) -> String {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        let startOfCurrentWeek = calendar.date(from: components)!
        
        let startOfSelectedWeek = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: startOfCurrentWeek)!
        let endOfSelectedWeek = calendar.date(byAdding: .day, value: 6, to: startOfSelectedWeek)!
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM"
        
        return "\(formatter.string(from: startOfSelectedWeek)) - \(formatter.string(from: endOfSelectedWeek))"
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [FocusSession.self, Activity.self], inMemory: true)
}
