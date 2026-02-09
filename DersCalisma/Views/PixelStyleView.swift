import SwiftUI
import SwiftData

// 1. Partikül Modeli (Aynı dosyada en üste ekleyebilirsin)
struct EnergyParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let speed: CGFloat
    let size: CGFloat
}

struct PixelStyleView: View {
    // iOS 17 Observation Framework uyumlu
    @Bindable var viewModel: TimerViewModel
    var modelContext: ModelContext
    
    // MARK: - PARTİKÜL STATE'LERİ (YENİ)
    @State private var particles: [EnergyParticle] = []
    
    // MARK: - RETRO AYARLAR
    let totalCells = 8 // Bataryadaki toplam kutu sayısı
    
    // 8-bit Renk Paleti
    let retroGreen = Color(red: 0.0, green: 0.8, blue: 0.2) // Parlak piksel yeşili
    let retroGray = Color(white: 0.8) // Sönük kutu rengi
    let outlineColor = Color.black // Kalın siyah çizgiler için
    
    // Zaman ve Hesaplama
    var minute: Int { viewModel.secondsElapsed / 60 }
    var progress: CGFloat { CGFloat(viewModel.secondsElapsed % 60) / 60.0 }
    
    var cellsFilledCount: Int {
        viewModel.secondsElapsed > 0 ? Int(progress * CGFloat(totalCells)) : 0
    }
    
    var body: some View {
        VStack(spacing: 40) {
            
            // MARK: - BATARYA GÖVDESİ
            VStack(spacing: 2) {
                // 1. Batarya Kutup Başı
                Rectangle()
                    .fill(outlineColor)
                    .frame(width: 60, height: 15)
                
                // 2. Ana Gövde
                ZStack {
                    // A) Kalın Dış Çerçeve
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(outlineColor, lineWidth: 8)
                        .background(Color.white)
                        .frame(width: 160, height: 300)
                    
                    // B) İçerik Alanı (Hücreler + Partiküller)
                    ZStack {
                        // B1. Hücreler (Senin Orijinal Kodun)
                        VStack(spacing: 4) {
                            ForEach((0..<totalCells).reversed(), id: \.self) { index in
                                let isCellActive = index < cellsFilledCount
                                
                                Rectangle()
                                    .fill(isCellActive ? retroGreen : retroGray)
                                    .shadow(color: isCellActive ? retroGreen.opacity(0.5) : .clear, radius: 4)
                                    .frame(height: 30)
                                    .overlay(
                                        Rectangle().stroke(outlineColor, lineWidth: 2)
                                    )
                            }
                        }
                        
                        // B2. PARTİKÜL EFEKTİ (YENİ KATMAN)
                        // Hücrelerin üzerine, çerçevenin içine çiziyoruz
                        GeometryReader { geometry in
                            let size = geometry.size
                            
                            TimelineView(.animation) { timeline in
                                Canvas { context, size in
                                    for particle in particles {
                                        let particleRect = CGRect(
                                            x: particle.x,
                                            y: particle.y,
                                            width: particle.size,
                                            height: particle.size
                                        )
                                        // Beyaz, hafif şeffaf enerji baloncukları
                                        context.fill(Path(particleRect), with: .color(.white.opacity(0.7)))
                                    }
                                }
                                .onChange(of: timeline.date) { _, _ in // iOS 17 Syntax
                                    updateParticles(in: size, isRunning: viewModel.isRunning)
                                }
                            }
                        }
                        // Partiküllerin hücrelerin dışına taşmasını engelle
                        .clipShape(Rectangle())
                        
                    }
                    .padding(12) // Dış çerçeve ile iç alan arasındaki boşluk
                    .frame(width: 160, height: 300)
                }
            }
            
            // MARK: - BİLGİ ALANI
            VStack(spacing: 5) {
                Text("\(minute)")
                    .font(.system(size: 80, weight: .heavy, design: .monospaced))
                    .foregroundColor(outlineColor)
                
                Text("DAKİKA")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(outlineColor.opacity(0.6))
                    .tracking(4)
            }
            
            // MARK: - BUTON
            Button(action: {
                withAnimation(.spring()) { viewModel.toggleTimer(context: modelContext) }
            }) {
                Text(viewModel.isRunning ? "DURAKLAT" : "BAŞLAT")
                    .font(.title3.bold().monospaced())
                    .foregroundColor(.white)
                    .frame(width: 220, height: 60)
                    .background(viewModel.isRunning ? Color.red : outlineColor)
                    .cornerRadius(4)
                    .shadow(color: outlineColor, radius: 0, x: 4, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4).stroke(Color.white, lineWidth: 2)
                            .padding(2)
                    )
            }
        }
    }
    
    // MARK: - PARTİKÜL FİZİĞİ (UPDATE LOOP)
    func updateParticles(in size: CGSize, isRunning: Bool) {
        // Sayaç duruyorsa partikülleri temizle
        guard isRunning else {
            if !particles.isEmpty { particles.removeAll() }
            return
        }
        
        // 1. Hareket
        for i in particles.indices {
            particles[i].y -= particles[i].speed // Yukarı çık
        }
        
        // 2. Temizlik (Ekranın tepesinden çıkanları sil)
        particles.removeAll { $0.y < -10 }
        
        // 3. Spawn (Yeni partikül yaratma)
        // %15 şansla yeni partikül (Piksel hissiyatı için düşük tuttum)
        if Int.random(in: 0...100) < 15 {
            let pixelScale: CGFloat = 4 // Partikül boyutu
            
            // Rastgele X konumu (Grid'e oturtulmuş)
            let randomX = CGFloat(Int.random(in: 0...Int(size.width)))
            let snappedX = randomX - (randomX.truncatingRemainder(dividingBy: pixelScale))
            
            let newParticle = EnergyParticle(
                x: snappedX,
                y: size.height, // En alttan başla
                speed: CGFloat(Int.random(in: 2...5)), // Rastgele hız
                size: pixelScale
            )
            particles.append(newParticle)
        }
    }
}

// Önizleme için Mock ViewModel (Sende zaten gerçek veri var, burası test için)
#Preview {
    // Not: Gerçek projede kendi ViewModel'ını koyacaksın
    PixelStyleView(viewModel: TimerViewModel(), modelContext: try! ModelContainer(for: FocusSession.self).mainContext)
}
