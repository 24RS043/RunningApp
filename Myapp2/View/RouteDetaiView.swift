//
//  RouteDetailView.swift
//  MyApp2
//

import SwiftUI
import MapKit

struct RouteDetailView: View {
    let record: RunRecord//1回分のランニング記録を受け取る
    
    // RoutePoint を地図用の座標に変換
    private var coordinates: [CLLocationCoordinate2D] {
        record.route.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 上半分：地図
            Map(initialPosition: .region(region)) {
                MapPolyline(coordinates: coordinates)//走行ルートを描く
                    .stroke(Color.blue, lineWidth: 5)//線のデザイン
            }
            
            // 下半分：ラップ一覧
            List {
                if record.laps.isEmpty {
                    Text("ラップの記録はありません")
                        .foregroundColor(.gray)
                } else {
                    ForEach(Array(record.laps.enumerated()), id: \.offset) { index, lapTime in
                        HStack {
                            Text("\(index + 1) km")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(String(format: "%d'%02d\"", lapTime / 60, lapTime % 60))
                                .bold()
                        }
                    }
                }
            }
        }
        .navigationTitle("走行ルート")
        .navigationBarTitleDisplayMode(.inline) //タイトルを小さく表示
    }
    
    // ルートが画面に収まるような表示範囲を計算
    private var region: MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        
        let lats = coordinates.map { $0.latitude }//最大・最小の緯度を取得
        let lons = coordinates.map { $0.longitude }//最大・最小の経度を取得
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
            //地図の中心を計算
        )
        let span = MKCoordinateSpan( //地図の拡大率を計算
            latitudeDelta: (lats.max()! - lats.min()!) * 1.5 + 0.001,
            longitudeDelta: (lons.max()! - lons.min()!) * 1.5 + 0.001
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
