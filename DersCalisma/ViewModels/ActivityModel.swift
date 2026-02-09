import Foundation
import SwiftData

@Model
class Activity {
    var name: String
    var createdDate: Date
    
    // İlişki: Activity silinirse bağlı session'lar da silinsin
    @Relationship(deleteRule: .cascade, inverse: \FocusSession.activity)
    var sessions: [FocusSession]? = []
    
    init(name: String) {
        self.name = name
        self.createdDate = Date()
    }
}

// 👇 BU KISIM TÜM HATALARIN ÇÖZÜMÜDÜR
// Bunu eklediğinde SwiftUI artık Activity'leri kıyaslayabilir
// ve animasyon/binding hataları kaybolur.
extension Activity: Equatable {
    static func == (lhs: Activity, rhs: Activity) -> Bool {
        // İsimleri ve oluşturulma tarihleri aynıysa bu iki ders aynıdır diyoruz.
        return lhs.name == rhs.name && lhs.createdDate == rhs.createdDate
    }
}
