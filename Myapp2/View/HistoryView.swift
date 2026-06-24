//
//  HistoryView.swift
//  MyApp2
//
//  Created by  KoudaTakuma       on 2026/06/17.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var store: RunRecordStore
    @ObservedObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.records) { record in
                    NavigationLink {
                        RouteDetailView(record: record)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(
                                record.date.formatted(date: .abbreviated, time: .shortened)
                            )
                            .font(.caption)
                            .foregroundColor(.gray)
                            
                            Text(String(format: "距離: %.2f m", record.distance))
                            Text("時間: \(record.time) 秒")
                            Text(String(format: "消費カロリー: %.1f kcal", record.calories))
                            if record.distance > 0 {
                                let pacePerKm = Double(record.time) / (record.distance / 1000)
                                let paceMinutes = Int(pacePerKm) / 60
                                let paceSeconds = Int(pacePerKm) % 60
                                Text(String(format: "平均ペース: %d'%02d\" /km", paceMinutes, paceSeconds))
                            }
                        }
                    }
                }
                .onDelete(perform: store.delete)
            }
            .navigationTitle("履歴")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("ログアウト") {
                        authManager.logout()
                    }
                }
            }
        }
    }
}
