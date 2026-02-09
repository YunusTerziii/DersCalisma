import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    
    // 1. Ayarları Çekiyoruz
    @Query private var settings: [UserSettings]
    
    // 2. ViewModel: Tüm sayaç ve aktivite verisi burada
    @State private var viewModel = TimerViewModel()
    
    // 3. Mağaza ekranı kontrolü
    @State private var showStore = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Ayarlar yüklendi mi diye kontrol et
                if let userSettings = settings.first,
                   let style = TimerStyle(rawValue: userSettings.selectedStyleID) {
                    
                    // --- 1. YENİ EKLENEN KISIM: AKTİVİTE SEÇİCİ ---
                    // Temalar değişse bile bu üstte sabit kalır.
                    ActivitySelectorView(viewModel: viewModel)
                        .padding(.top, 10)
                        .padding(.bottom, 10) // Temalarla arasına biraz boşluk
                    
                    // --- 2. TEMA DEĞİŞTİRİCİ (MEVCUT KODUN) ---
                    // Kalan boşluğu doldurması için Spacer veya frame ayarı gerekebilir
                    // ama şimdilik senin yapını koruyoruz.
                    switch style {
                    case .circular:
                        CircularStyleView(viewModel: viewModel, modelContext: modelContext)
                    case .hourglass:
                        HourglassStyleView(viewModel: viewModel, modelContext: modelContext)
                    case .pixel:
                        PixelStyleView(viewModel: viewModel, modelContext: modelContext)
                    }
                    
                    Spacer() // Temaları yukarı itmemesi için alta boşluk
                    
                } else {
                    // Yükleniyor ekranı
                    ProgressView("Yükleniyor...")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showStore = true }) {
                        Label("Mağaza", systemImage: "storefront.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showStore) {
                StoreView()
            }
            .onAppear {
                initializeSettingsIfNeeded()
            }
            // --- 3. YENİ EKLENEN KISIM: ÖZET POPUP'I ---
            // ViewModel içindeki showRewardPopup true olduğunda çalışır
            .alert("Oturum Özeti", isPresented: $viewModel.showRewardPopup) {
                Button("Harika!", role: .cancel) { }
            } message: {
                Text(viewModel.summaryMessage)
            }
        }
    }
    
    // Varsayılan ayarları oluşturma (Aynı kaldı)
    private func initializeSettingsIfNeeded() {
        if settings.isEmpty {
            let defaultSettings = UserSettings()
            modelContext.insert(defaultSettings)
            try? modelContext.save()
        }
    }
}

// Önizleme
#Preview {
    TimerView()
        .modelContainer(for: [FocusSession.self, UserSettings.self, Activity.self], inMemory: true)
}
