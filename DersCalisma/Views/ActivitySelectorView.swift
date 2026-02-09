import SwiftUI
import SwiftData

struct ActivitySelectorView: View {
    var viewModel: TimerViewModel // Binding değil, düz referans
    
    @Query(sort: \Activity.name, order: .forward) var activities: [Activity]
    @State private var showAddActivitySheet = false
    
    var body: some View {
        HStack {
            Menu {
                // Seçenek 1: Genel Çalışma
                Button {
                    updateActivitySafe(to: nil)
                } label: {
                    Label("Genel Çalışma", systemImage: "square.grid.2x2")
                }
                
                Divider()
                
                // Seçenek 2: Dersler
                ForEach(activities) { activity in
                    Button {
                        updateActivitySafe(to: activity)
                    } label: {
                        // Kıyaslamayı ID üzerinden yapıyoruz (HATA ÇÖZÜMÜ)
                        if viewModel.selectedActivity?.persistentModelID == activity.persistentModelID {
                            Label(activity.name, systemImage: "checkmark")
                        } else {
                            Text(activity.name)
                        }
                    }
                }
                
                Divider()
                
                Button {
                    showAddActivitySheet = true
                } label: {
                    Label("Yeni Ders Ekle...", systemImage: "plus")
                }
                
            } label: {
                // GÖRÜNÜM KISMI
                HStack(spacing: 10) {
                    Image(systemName: viewModel.selectedActivity == nil ? "timer" : "tag.fill")
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AKTİVİTE")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        // İçerik değişirken animasyon çakışmasını önlemek için .id ekliyoruz
                        Text(viewModel.selectedActivity?.name ?? "Genel Çalışma")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            // HATA ÇÖZÜMÜ: Metin değişimi için ID tanımlıyoruz
                            .id(viewModel.selectedActivity?.persistentModelID)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $showAddActivitySheet) {
            ActivityManagerView()
                .presentationDetents([.medium])
        }
    }
    
    // Güvenli güncelleme fonksiyonu
    private func updateActivitySafe(to activity: Activity?) {
        withAnimation {
            viewModel.updateActivity(to: activity)
        }
    }
}
