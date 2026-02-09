//
//  CircularStyleView.swift
//  DersCalisma
//
//  Created by Yunus Terzi on 31.01.2026.
//

import SwiftUI
import SwiftData

struct CircularStyleView: View {
    @Bindable var viewModel: TimerViewModel
    var modelContext: ModelContext // Buton aksiyonu için lazım
    
    // Renkler
    let softOrange = Color.orange
    
    var body: some View {
        VStack(spacing: 50) {
            ZStack {
                // Sabit Halka
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 20)
                    .frame(width: 280, height: 280)
                
                // Hareketli Halka
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.totalSecondsElapsed % 60) / 60.0 == 0 && viewModel.totalSecondsElapsed > 0 ? 1.0 : CGFloat(viewModel.totalSecondsElapsed % 60) / 60.0)
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: [softOrange.opacity(0.5), softOrange]), center: .center),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: viewModel.totalSecondsElapsed)
                    .shadow(color: softOrange.opacity(0.3), radius: 10, x: 0, y: 5)
                
                // Metin
                VStack {
                    Text("\(viewModel.totalSecondsElapsed / 60)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                    Text("DAKİKA")
                        .font(.caption).bold().tracking(3)
                }
                .foregroundColor(.brown)
            }
            
            // Buton
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
}
