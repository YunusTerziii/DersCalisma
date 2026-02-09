//
//  ActivityManagerView.swift
//  DersCalisma
//
//  Created by Yunus Terzi on 31.01.2026.
//

import SwiftUI
import SwiftData

struct ActivityManagerView: View {
    @Environment(\.modelContext) private var modelContext
    // Kayıtlı aktiviteleri çekiyoruz
    @Query(sort: \Activity.name, order: .forward) var activities: [Activity]
    
    @State private var newActivityName = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Yeni Ders Ekle")) {
                    HStack {
                        TextField("Örn: AYT Matematik", text: $newActivityName)
                        Button(action: addActivity) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newActivityName.isEmpty)
                    }
                }
                
                Section(header: Text("Kayıtlı Derslerim")) {
                    ForEach(activities) { activity in
                        Text(activity.name)
                    }
                    .onDelete(perform: deleteActivity)
                }
            }
            .navigationTitle("Dersler")
        }
    }
    
    func addActivity() {
        let activity = Activity(name: newActivityName)
        modelContext.insert(activity)
        newActivityName = "" // Kutuyu temizle
    }
    
    func deleteActivity(at offsets: IndexSet) {
        for index in offsets {
            let activity = activities[index]
            modelContext.delete(activity)
        }
    }
}
