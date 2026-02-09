import Foundation
import SwiftData
import Observation

// Geçici hafıza için ufak bir yapı (Class dışında durmalı)
struct StudySegment {
    var activity: Activity?
    var durationSeconds: Int
}

@Observable
class TimerViewModel {
    // MARK: - Properties
    var selectedActivity: Activity? = nil
    
    // Toplam süre (Ekranda görünen)
    var totalSecondsElapsed: Int = 0
    
    // Şu anki aktivite için geçen süre (Arka plandaki sayaç)
    var currentSegmentSeconds: Int = 0
    
    var isRunning: Bool = false
    
    // Geçmiş parçaları tutan liste
    var completedSegments: [StudySegment] = []
    
    // Puan ve Popup
    var showRewardPopup: Bool = false
    var summaryMessage: String = ""
    
    private var timer: Timer?
    
    // Ekranda Toplam Süreyi Gösterir (00:00 formatında)
    var timeDisplay: String {
        let minutes = totalSecondsElapsed / 60
        let seconds = totalSecondsElapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Functions
    
    // 1. DERS DEĞİŞTİRME FONKSİYONU
    func updateActivity(to newActivity: Activity?) {
        // Eğer sayaç çalışıyorsa ve bir süre geçmişse, eski dersi paketle
        if isRunning && currentSegmentSeconds > 0 {
            let segment = StudySegment(activity: selectedActivity, durationSeconds: currentSegmentSeconds)
            completedSegments.append(segment)
            
            // Yeni ders için ara sayacı sıfırla
            currentSegmentSeconds = 0
        }
        
        // Dersi değiştir
        selectedActivity = newActivity
    }
    
    func toggleTimer(context: ModelContext) {
        if isRunning {
            stopTimer(context: context)
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.totalSecondsElapsed += 1
            self.currentSegmentSeconds += 1 // Her ikisi de artıyor
        }
    }
    
    func stopTimer(context: ModelContext) {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // Son kalan parçayı da listeye ekle
        if currentSegmentSeconds > 0 {
            let segment = StudySegment(activity: selectedActivity, durationSeconds: currentSegmentSeconds)
            completedSegments.append(segment)
        }
        
        // --- KAYIT VE ÖZET İŞLEMLERİ ---
        processAndSaveSessions(context: context)
        
        // Her şeyi sıfırla
        totalSecondsElapsed = 0
        currentSegmentSeconds = 0
        completedSegments.removeAll()
    }
    
    // MARK: - KAYIT MANTIĞI (GÜNCELLENDİ)
    private func processAndSaveSessions(context: ModelContext) {
        // Eğer hiç çalışma yoksa çık
        guard !completedSegments.isEmpty else { return }
        
        var totalPoints = 0
        var summaryLines: [String] = []
        
        // Zamanı "Geriye Doğru" takip etmek için değişken
        // (En son bitiş saati = Şu an)
        var currentTrackingTime = Date()
        
        // Listeyi TERSTEN dönüyoruz (reversed).
        // Neden? Çünkü "Şu an"dan geriye doğru giderek başlangıç saatlerini bulacağız.
        // Örn: Saat 15:00. Son ders Fizik (30dk). Fizik Başlangıç = 14:30.
        // Bir önceki ders Mat (30dk). Mat Başlangıç = 14:00.
        for segment in completedSegments.reversed() {
            
            let minutes = max(1, segment.durationSeconds / 60) // En az 1 dk sayıyoruz
            let points = minutes * 1
            
            // BAŞLANGIÇ SAATİNİ HESAPLA
            // Bitiş zamanından süreyi çıkarıyoruz
            let startDate = Calendar.current.date(byAdding: .second, value: -segment.durationSeconds, to: currentTrackingTime) ?? currentTrackingTime
            
            // VERİTABANINA KAYDET
            // 'date' parametresine hesapladığımız startDate'i veriyoruz
            let session = FocusSession(durationMinutes: minutes, date: startDate, activity: segment.activity)
            context.insert(session)
            
            // BİR SONRAKİ DÖNGÜ İÇİN BİTİŞ ZAMANI GÜNCELLE
            // Bu dersin başlangıcı, bir önceki dersin bitişi kabul edilir.
            currentTrackingTime = startDate
            
            totalPoints += points
            
            // Özet metni için (Başa ekliyoruz ki listede kronolojik dursun)
            let name = segment.activity?.name ?? "Genel Çalışma"
            let timeString = startDate.formatted(date: .omitted, time: .shortened)
            summaryLines.insert("• \(name): \(minutes) dk (\(timeString))", at: 0)
        }
        
        // Özeti Oluştur
        let totalTime = completedSegments.reduce(0) { $0 + $1.durationSeconds } / 60
        
        summaryMessage = """
        Toplam Süre: \(totalTime) dakika
        Kazanılan Puan: \(totalPoints)
        
        Detaylar:
        \(summaryLines.joined(separator: "\n"))
        """
        
        showRewardPopup = true
    }
}
