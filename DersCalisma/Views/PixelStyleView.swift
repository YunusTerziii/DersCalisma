import SwiftUI
import SwiftData

// 1. Partikül Modeli
struct EnergyParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let speed: CGFloat
    // size artık tek bir pikselin boyutu olacak, tüm şeklin değil.
}

// 2. ŞİMŞEK DESENİ (5x7 Piksel Grid)
// 1: Boya, 0: Boş geç
let boltPattern: [[Int]] = [
    [0, 0, 1, 1, 0], // Üst kısım
    [0, 1, 1, 0, 0],
    [1, 1, 1, 1, 1], // Orta flaş
    [0, 0, 0, 1, 1],
    [0, 0, 1, 1, 0],
    [0, 1, 1, 0, 0],
    [0, 1, 0, 0, 0]  // Alt uç
]

struct PixelStyleView: View {
    @Bindable var viewModel: TimerViewModel
    var modelContext: ModelContext
    
    // MARK: - PARTİKÜL STATE
    @State private var particles: [EnergyParticle] = []
    let particlePixelSize: CGFloat = 3 // Şimşeği oluşturan her minik karenin boyutu
    
    // MARK: - RETRO AYARLAR
    let totalCells = 8
    let retroGreen = Color(red: 0.0, green: 0.8, blue: 0.2)
    let retroGray = Color(white: 0.8)
    let outlineColor = Color.black
    
    var minute: Int { viewModel.totalSecondsElapsed / 60 }
    var progress: CGFloat { CGFloat(viewModel.totalSecondsElapsed % 60) / 60.0 }

    var cellsFilledCount: Int {
        viewModel.totalSecondsElapsed > 0 ? Int(progress * CGFloat(totalCells)) : 0
    }
    
    var body: some View {
        VStack(spacing: 40) {
            
            // MARK: - BATARYA GÖVDESİ
            VStack(spacing: 2) {
                Rectangle()
                    .fill(outlineColor)
                    .frame(width: 60, height: 15)
                
                ZStack {
                    // Dış Çerçeve
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(outlineColor, lineWidth: 8)
                        .background(Color.white)
                        .frame(width: 160, height: 300)
                    
                    // İçerik Alanı
                    ZStack {
                        // B1. Hücreler (Sabit Kalan Kısım)
                        VStack(spacing: 4) {
                            ForEach((0..<totalCells).reversed(), id: \.self) { index in
                                let isCellActive = index < cellsFilledCount
                                Rectangle()
                                    .fill(isCellActive ? retroGreen : retroGray)
                                    .shadow(color: isCellActive ? retroGreen.opacity(0.5) : .clear, radius: 4)
                                    .frame(height: 30)
                                    .overlay(Rectangle().stroke(outlineColor, lineWidth: 2))
                            }
                        }
                        
                        // B2. ŞİMŞEK EFEKTİ (GÜNCELLENDİ)
                        GeometryReader { geometry in
                            let size = geometry.size
                            TimelineView(.animation) { timeline in
                                Canvas { context, size in
                                    // Her partikül için döngü
                                    for particle in particles {
                                        
                                        // Şimşek desenini çizme döngüsü (Nested Loop)
                                        for row in 0..<boltPattern.count {
                                            for col in 0..<boltPattern[row].count {
                                                // Eğer desende '1' varsa oraya piksel koy
                                                if boltPattern[row][col] == 1 {
                                                    // Konumu hesapla: Partikülün ana konumu + desendeki sıra/sütun ofseti
                                                    let pixelX = particle.x + CGFloat(col) * particlePixelSize
                                                    let pixelY = particle.y + CGFloat(row) * particlePixelSize
                                                    
                                                    let pixelRect = CGRect(
                                                        x: pixelX,
                                                        y: pixelY,
                                                        width: particlePixelSize,
                                                        height: particlePixelSize
                                                    )
                                                    // RETRO YEŞİL RENK İLE BOYA
                                                    context.fill(Path(pixelRect), with: .color(retroGreen))
                                                }
                                            }
                                        }
                                    }
                                }
                                .onChange(of: timeline.date) { _, _ in
                                    updateParticles(in: size, isRunning: viewModel.isRunning)
                                }
                            }
                        }
                        .clipShape(Rectangle())
                    }
                    .padding(12)
                    .frame(width: 160, height: 300)
                }
            }
            
            // MARK: - BİLGİ ALANI ve BUTON (Değişmedi)
            VStack(spacing: 5) {
                Text("\(minute)")
                    .font(.system(size: 80, weight: .heavy, design: .monospaced))
                    .foregroundColor(outlineColor)
                Text("DAKİKA")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(outlineColor.opacity(0.6))
                    .tracking(4)
            }
            
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
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white, lineWidth: 2).padding(2))
            }
        }
    }
    
    // MARK: - PARTİKÜL FİZİĞİ
    func updateParticles(in size: CGSize, isRunning: Bool) {
        guard isRunning else {
            if !particles.isEmpty { particles.removeAll() }
            return
        }
        
        for i in particles.indices {
            particles[i].y -= particles[i].speed
        }
        
        // Şimşek boyutu kadar yukarı çıkınca sil (yaklaşık 7 satır * 3 piksel = 21)
        particles.removeAll { $0.y < -30 }
        
        // Spawn oranını biraz düşürdüm çünkü şimşekler daha büyük ve dikkat çekici
        if Int.random(in: 0...100) < 2 {
            let gridSize: CGFloat = 4 // Grid'e oturtma hassasiyeti
            let randomX = CGFloat(Int.random(in: 0...Int(size.width - 20))) // Sağdan taşmasın diye -20
            let snappedX = randomX - (randomX.truncatingRemainder(dividingBy: gridSize))
            
            let newParticle = EnergyParticle(
                x: snappedX,
                y: size.height,
                speed: CGFloat(Int.random(in: 1...2)),
            )
            particles.append(newParticle)
        }
    }
}

