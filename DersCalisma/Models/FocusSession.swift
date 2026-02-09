//
//  FocusSession.swift
//  DersCalisma
//
//  Created by Yunus Terzi on 31.01.2026.
//

import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID
    var date: Date
    var durationMinutes: Int
    var pointsEarned: Int
    
    // İlişki: Bu oturum hangi derse ait?
    var activity: Activity?
    
    // GÜNCELLENEN INIT FONKSİYONU:
    // Artık 'date' parametresi alıyor.
    // Eğer tarih verilmezse 'Date()' (Şu an) kabul eder.
    init(durationMinutes: Int, date: Date = Date(), activity: Activity? = nil) {
        self.id = UUID()
        self.date = date // <-- Burası çok önemli, dışarıdan gelen tarihi kaydediyoruz
        self.durationMinutes = durationMinutes
        
        // Puan hesaplama mantığın korundu
        self.pointsEarned = durationMinutes * 1
        
        // Dışarıdan gelen aktiviteyi kaydediyoruz
        self.activity = activity
    }
}

// EKSTRA ÖZELLİK:
// Detay sayfasında bitiş saatini göstermek için (Örn: 15:00 - 15:45)
// Bu bir değişken değil, hesaplanan bir değer olduğu için hata vermez.
extension FocusSession {
    var endTime: Date {
        Calendar.current.date(byAdding: .minute, value: durationMinutes, to: date) ?? date
    }
}
