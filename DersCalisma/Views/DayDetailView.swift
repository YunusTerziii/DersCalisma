import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date
    
    // O tarihe ait verileri çekecek sorgu
    @Query var sessions: [FocusSession]
    
    init(date: Date) {
        self.date = date
        
        // SwiftData Predicate ile SADECE o günü (00:00 - 23:59) filtreliyoruz
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // init içinde Query'yi oluşturuyoruz (Tarihe göre sıralı)
        _sessions = Query(filter: #Predicate { session in
            session.date >= startOfDay && session.date < endOfDay
        }, sort: \.date, order: .reverse)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "Kayıt Yok",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Bu tarihte herhangi bir çalışma kaydı bulunamadı.")
                    )
                } else {
                    List {
                        // ÖZET BÖLÜMÜ (Toplam Çalışma)
                        Section {
                            HStack {
                                Text("Günlük Toplam")
                                Spacer()
                                Text("\(totalMinutes) dk")
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // DERS DETAYLARI VE SAAT ARALIKLARI
                        Section(header: Text("ÇALIŞMALAR")) {
                            ForEach(sessions) { session in
                                HStack {
                                    // SOL: İkon ve Ders Adı
                                    Label(
                                        session.activity?.name ?? "Genel Çalışma",
                                        systemImage: "book.fill"
                                    )
                                    .foregroundColor(session.activity == nil ? .gray : .orange)
                                    
                                    Spacer()
                                    
                                    // SAĞ: Saat Aralığı ve Süre
                                    VStack(alignment: .trailing, spacing: 4) {
                                        
                                        // 1. SAAT ARALIĞI (Örn: 14:30 - 15:15)
                                        // start ve end time'ı formatlayıp yan yana yazıyoruz
                                        Text("\(session.date.formatted(date: .omitted, time: .shortened)) - \(session.endTime.formatted(date: .omitted, time: .shortened))")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(4)
                                            .foregroundColor(.secondary)
                                        
                                        // 2. SÜRE (Örn: 45 dk)
                                        HStack(spacing: 2) {
                                            Image(systemName: "hourglass")
                                                .font(.caption2)
                                            Text("\(session.durationMinutes) dk")
                                        }
                                        .font(.caption.bold())
                                        .foregroundColor(.primary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            // Başlık: Tarihi güzel formatta göster (12 Şubat Pazartesi)
            .navigationTitle(dateFormatted)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // O günkü toplam süreyi hesaplar
    var totalMinutes: Int {
        sessions.reduce(0) { $0 + $1.durationMinutes }
    }
    
    // Başlık formatı
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM EEEE"
        return formatter.string(from: date)
    }
}

