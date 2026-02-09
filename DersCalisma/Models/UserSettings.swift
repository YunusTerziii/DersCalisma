//
//  UserSettings.swift
//  DersCalisma
//
//  Created by Yunus Terzi on 31.01.2026.
//

import Foundation
import SwiftData

// 1. Tema Seçenekleri
// Kodun içinde "circular" veya "hourglass" diye yazarak temayı tanıyacağız.
enum TimerStyle: String, Codable, CaseIterable {
    case circular // İlk yaptığımız Yuvarlak tasarım
    case hourglass // Kum Saati tasarımı
    case pixel // Pixel Batarya
    
    // Mağazada görünecek isimler
    var displayName: String {
        switch self {
        case .circular: return "Klasik Halka"
        case .hourglass: return "Kum Saati"
        case .pixel : return "Piksel Batarya"
        }
    }
    
    // Mağaza Fiyatları
    var price: Int {
        switch self {
        case .circular: return 0 // Başlangıçta bedava
        case .hourglass: return 1
        case .pixel: return 2
        }
    }
}

// 2. Veritabanı Modeli
@Model
class UserSettings {
    var selectedStyleID: String // Şu an kullandığın tema
    var unlockedStyleIDs: [String] // Satın aldığın temaların listesi
    var spentPoints: Int // Mağazada harcanan toplam puan
    
    init() {
        // Uygulama ilk açıldığında varsayılan ayarlar:
        self.selectedStyleID = TimerStyle.circular.rawValue
        self.unlockedStyleIDs = [TimerStyle.circular.rawValue]
        self.spentPoints = 0
    }
}
