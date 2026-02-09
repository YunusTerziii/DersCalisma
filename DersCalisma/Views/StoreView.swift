import SwiftUI
import SwiftData

struct StoreView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss // Mağazayı kapatmak için
    
    // Veriler
    @Query private var settings: [UserSettings]
    @Query private var sessions: [FocusSession]
    
    // Renk Paleti
    let softOrange = Color.orange
    let warmBeige = Color(red: 0.98, green: 0.96, blue: 0.92)
    let cardBackground = Color.white
    
    // Bakiye Hesabı
    var currentBalance: Int {
        let totalEarned = sessions.reduce(0) { $0 + $1.pointsEarned }
        let totalSpent = settings.first?.spentPoints ?? 0
        return totalEarned - totalSpent
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Arka Plan
                warmBeige.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // 2. Üst Bilgi Paneli (Cüzdan)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("BAKİYEN")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .tracking(2)
                            
                            HStack(spacing: 5) {
                                Image(systemName: "star.circle.fill")
                                    .foregroundColor(softOrange)
                                Text("\(currentBalance)")
                                    .contentTransition(.numericText()) // Sayı değişirken animasyonlu döner
                            }
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(.brown)
                        }
                        Spacer()
                        
                        // Kapat Butonu (Sheet olduğu için)
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray.opacity(0.3))
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // 3. COVER FLOW ALANI (Yatay Kaydırma)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) { // Aralarındaki boşluğu padding ile kontrol edeceğiz
                            ForEach(TimerStyle.allCases, id: \.self) { style in
                                StoreCard(style: style)
                                    // Kartın genişliği ekranın genişliğinden biraz az olsun
                                    .containerRelativeFrame(.horizontal, count: 1, spacing: 40)
                                    // SİHİRLİ KISIM: Kaydırma Animasyonu 🪄
                                    .scrollTransition { content, phase in
                                        content
                                            .opacity(phase.isIdentity ? 1.0 : 0.6) // Ortada değilse soluklaş
                                            .scaleEffect(phase.isIdentity ? 1.0 : 0.85) // Ortada değilse küçül
                                            .rotation3DEffect(
                                                .degrees(phase.value * -10), // Hafif 3D dönme efekti
                                                axis: (x: 0, y: 1, z: 0)
                                            )
                                    }
                            }
                        }
                        .scrollTargetLayout() // Hedef belirleme
                    }
                    .scrollTargetBehavior(.viewAligned) // Kartın tam ortada durmasını sağlar (Snap)
                    .safeAreaPadding(.vertical, 20)
                    
                    Spacer()
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - KART TASARIMI
    @ViewBuilder
    func StoreCard(style: TimerStyle) -> some View {
        if let userSettings = settings.first {
            let isUnlocked = userSettings.unlockedStyleIDs.contains(style.rawValue)
            let isSelected = userSettings.selectedStyleID == style.rawValue
            
            VStack(spacing: 0) {
                // Görsel Alanı (Üst Yarısı)
                ZStack {
                    Color.brown.opacity(0.05)
                    
                    // İkon / Önizleme
                    Image(systemName: style == .circular ? "circle.dashed" : "hourglass")
                        .font(.system(size: 80))
                        .foregroundColor(softOrange)
                        .shadow(color: softOrange.opacity(0.3), radius: 10, x: 0, y: 10)
                }
                .frame(height: 250)
                
                // Bilgi Alanı (Alt Yarısı)
                VStack(spacing: 15) {
                    VStack(spacing: 5) {
                        Text(style.displayName)
                            .font(.title2.bold())
                            .foregroundColor(.brown)
                        
                        Text(style == .circular ? "Klasik ve sade." : "Zamanın akışını hisset.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Buton Mantığı
                    if isSelected {
                        Button {} label: {
                            Label("Kullanılıyor", systemImage: "checkmark")
                                .font(.headline)
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(15)
                        }
                        .disabled(true)
                    } else if isUnlocked {
                        Button(action: {
                            withAnimation { userSettings.selectedStyleID = style.rawValue }
                        }) {
                            Text("Seç")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(15)
                                .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 5)
                        }
                    } else {
                        Button(action: {
                            buyTheme(style: style, settings: userSettings)
                        }) {
                            HStack {
                                Text("Satın Al")
                                Spacer()
                                Text("\(style.price) P")
                                    .fontWeight(.heavy)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(currentBalance >= style.price ? softOrange : Color.gray)
                            .cornerRadius(15)
                            .shadow(color: (currentBalance >= style.price ? softOrange : .gray).opacity(0.3), radius: 5, x: 0, y: 5)
                        }
                        .disabled(currentBalance < style.price)
                    }
                }
                .padding(25)
                .background(Color.white)
            }
            .cornerRadius(30)
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 10) // Kartlar birbirine yapışmasın
        } else {
            ProgressView()
        }
    }
    
    func buyTheme(style: TimerStyle, settings: UserSettings) {
        if currentBalance >= style.price {
            // Basit bir başarı titreşimi
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            withAnimation {
                settings.spentPoints += style.price
                settings.unlockedStyleIDs.append(style.rawValue)
                settings.selectedStyleID = style.rawValue
            }
        } else {
            // Hata titreşimi
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}

#Preview {
    StoreView()
        .modelContainer(for: [FocusSession.self, UserSettings.self], inMemory: true)
}
