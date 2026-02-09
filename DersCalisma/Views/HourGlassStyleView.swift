import SwiftUI
import SwiftData

struct HourglassStyleView: View {
    @Bindable var viewModel: TimerViewModel
    var modelContext: ModelContext
    
    // MARK: - PROFESYONEL RENK PALETİ & GRADYANLAR
    
    // Kum için derinlikli gradyan (Üstü açık, altı koyu)
    let sandGradient = LinearGradient(
        gradient: Gradient(colors: [Color(red: 1.0, green: 0.7, blue: 0.2), Color(red: 0.8, green: 0.4, blue: 0.0)]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Cam çerçeve için metalik/cam efekti veren gradyan
    let glassFrameGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.white.opacity(0.6), // Işık yansıması
            Color(red: 0.4, green: 0.3, blue: 0.2), // Ana kahverengi
            Color(red: 0.3, green: 0.2, blue: 0.1) // Gölge
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    let containerWidth: CGFloat = 180 // Biraz daha genişlettim
    let containerHeight: CGFloat = 260
    
    // MARK: - ZAMAN VE FİZİK (Aynı kalıyor)
    var minute: Int { viewModel.totalSecondsElapsed / 60 }
    var isRotated: Bool { minute % 2 != 0 }
    var t: CGFloat { CGFloat(viewModel.totalSecondsElapsed % 60) / 60.0 }
    
    // Simetrik Geometri Motoru (En mantıklı olanı)
    var drainingProgress: CGFloat { sqrt(1.0 - t) }
    var fillingProgress: CGFloat { 1.0 - sqrt(1.0 - t) }
    
    var invertedTriangleHeight: CGFloat { isRotated ? fillingProgress : drainingProgress }
    var uprightTriangleHeight: CGFloat { isRotated ? drainingProgress : fillingProgress }
    
    var rotationAngle: Double { Double(minute) * 180 }
    
    var body: some View {
        VStack(spacing: 50) {
            
            ZStack {
                // 1. GÖLGE KATMANI (En arkada, derinlik için)
                FullHourglassShape()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: containerWidth, height: containerHeight)
                    .offset(x: 0, y: 10) // Hafif aşağı kaydırılmış gölge
                    .blur(radius: 10) // Yumuşak gölge
                
                // 2. CAM ÇERÇEVE (Gradyan ile 3D efekti)
                FullHourglassShape()
                    .stroke(glassFrameGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    .frame(width: containerWidth, height: containerHeight)
                    // İçine hafif bir cam parlaklığı ekleyelim
                    .background(FullHourglassShape().fill(Color.white.opacity(0.1)))
                
                // 3. KUMLAR VE AKIŞ
                GeometryReader { geo in
                    let midX = geo.size.width / 2
                    let midY = geo.size.height / 2
                    let halfHeight = geo.size.height / 2
                    
                    ZStack(alignment: .top) {
                        
                        // A) ÜST KUM (Hacimli Gradyan)
                        TriangleContentShape(top: true)
                            .fill(sandGradient) // Düz renk yerine gradyan
                            .mask(Rectangle().fractionalHeight(invertedTriangleHeight, bottomToTop: false))
                            .frame(width: containerWidth, height: halfHeight)
                            // Kuma hafif iç gölge vererek hacim katalım
                            .overlay(
                                TriangleContentShape(top: true)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 2)
                                    .mask(Rectangle().fractionalHeight(invertedTriangleHeight, bottomToTop: false))
                            )
                        
                        // B) ALT KUM (Hacimli Gradyan)
                        TriangleContentShape(top: false)
                            .fill(sandGradient) // Düz renk yerine gradyan
                            .mask(Rectangle().fractionalHeight(uprightTriangleHeight, bottomToTop: true))
                            .frame(width: containerWidth, height: halfHeight)
                            .offset(y: halfHeight)
                        
                        // C) AKIŞ ÇİZGİSİ (Daha yumuşak)
                        if viewModel.isRunning {
                            let currentFillLevel = isRotated ? invertedTriangleHeight : uprightTriangleHeight
                            
                            if currentFillLevel < 0.99 {
                                Path { path in
                                    path.move(to: CGPoint(x: midX, y: midY))
                                    let emptySpace = halfHeight * (1.0 - currentFillLevel)
                                    let direction: CGFloat = isRotated ? -1.0 : 1.0
                                    path.addLine(to: CGPoint(x: midX, y: midY + (emptySpace * direction)))
                                }
                                .stroke(sandGradient, lineWidth: 4) // Biraz daha kalın
                                .blur(radius: 1) // Hafif bulanıklık ile "akışkan" hissi
                            }
                        }
                    }
                }
                .frame(width: containerWidth, height: containerHeight)
                // Kumların taşmaması için çerçeve içi maskeleme
                .mask(FullHourglassShape().frame(width: containerWidth - 8, height: containerHeight - 8))
            }
            .rotationEffect(.degrees(rotationAngle))
            .animation(.spring(response: 0.8, dampingFraction: 0.7), value: rotationAngle)
            
            // MARK: - BİLGİ ALANI (Tipografi İyileştirmesi)
            VStack(spacing: 0) {
                Text("\(minute)")
                    .font(.system(size: 90, weight: .black, design: .rounded))
                    .foregroundStyle(glassFrameGradient) // Yazıya da aynı metalik dokuyu verelim
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                
                Text("DAKİKA")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.brown.opacity(0.6))
                    .tracking(6) // Harf aralığını iyice açtık
                    .offset(y: -5)
            }
            
            // MARK: - BUTON (Daha Premium)
            Button(action: {
                withAnimation(.spring()) { viewModel.toggleTimer(context: modelContext) }
            }) {
                Text(viewModel.isRunning ? "Duraklat" : "Başla")
                    .font(.title3.bold()).foregroundColor(.white)
                    .frame(width: 220, height: 65)
                    .background(
                        // Butona da hafif gradyan
                        LinearGradient(colors: [viewModel.isRunning ? Color.red.opacity(0.8) : Color.brown, viewModel.isRunning ? Color.red : Color.brown.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1) // İnce bir parlama çizgisi
                    )
            }
        }
    }
}

// MARK: - ŞEKİLLER (Aynı kalıyor)
struct FullHourglassShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct TriangleContentShape: Shape {
    var top: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        if top {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        path.closeSubpath()
        return path
    }
}

extension View {
    func fractionalHeight(_ fraction: CGFloat, bottomToTop: Bool) -> some View {
        GeometryReader { geo in
            VStack {
                if bottomToTop { Spacer(minLength: 0) }
                Rectangle().frame(height: geo.size.height * fraction)
                if !bottomToTop { Spacer(minLength: 0) }
            }
        }
    }
}
