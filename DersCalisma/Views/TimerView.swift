//
//  TimerView.swift
//  DersCalisma
//
//  Created by Yunus Terzi on 31.01.2026.
//
import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TimerViewModel()
    
    // Cozy Renk Paleti
    let softOrange = Color.orange
    let warmBeige = Color(red: 0.98, green: 0.96, blue: 0.92)
    
    var body: some View {
        ZStack {
            warmBeige.ignoresSafeArea()
            
            VStack(spacing: 50) {
                ZStack {
                    // Sabit Arka Plan Halkası
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 20)
                        .frame(width: 280, height: 280)
                    
                    // Hareketli Dış Çember (60 saniyede bir tam tur)
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.secondsElapsed % 60) / 60.0 == 0 && viewModel.secondsElapsed > 0 ? 1.0 : CGFloat(viewModel.secondsElapsed % 60) / 60.0)
                        .stroke(
                            AngularGradient(gradient: Gradient(colors: [softOrange.opacity(0.5), softOrange]), center: .center),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                        // Akıcı dönüş animasyonu
                        .animation(.linear(duration: 1.0), value: viewModel.secondsElapsed)
                        .shadow(color: softOrange.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    // Süre Metni (Sadece Dakika Gösterimi)
                    VStack {
                        Text("\(viewModel.secondsElapsed / 60)")
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                        Text("DAKİKA")
                            .font(.caption).bold()
                            .tracking(3)
                    }
                    .foregroundColor(.brown)
                }
                
                // Başlat/Bitir Butonu
                Button(action: {
                    withAnimation(.spring()) {
                        viewModel.toggleTimer(context: modelContext)
                    }
                }) {
                    Text(viewModel.isRunning ? "Oturumu Bitir" : "Odaklanmaya Başla")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 240, height: 65)
                        .background(viewModel.isRunning ? Color.red.opacity(0.6) : softOrange)
                        .clipShape(Capsule())
                        .shadow(radius: 10)
                }
            }
        }
        .navigationTitle("Odak Vakti")
    }
}
#Preview {
    TimerView()
        .modelContainer(for: FocusSession.self, inMemory: true)
}

