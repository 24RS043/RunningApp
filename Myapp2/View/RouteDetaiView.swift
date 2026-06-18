//
//  RouteDetailView.swift
//  MyApp2
//

import SwiftUI
import MapKit

struct RouteDetailView: View {
    let record: RunRecord

    // RoutePoint を地図用の座標に変換
    private var coordinates: [CLLocationCoordinate2D] {
        record.route.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
    }

    var body: some View {
        Map(initialPosition: .region(region)) {
            MapPolyline(coordinates: coordinates)
                .stroke(Color.blue, lineWidth: 5)
        }
        .ignoresSafeArea(edges: .bottom) //下の余白まで地図を広げる
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

        let lats = coordinates.map { $0.latitude }
        let lons = coordinates.map { $0.longitude }
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: (lats.max()! - lats.min()!) * 1.5 + 0.001,
            longitudeDelta: (lons.max()! - lons.min()!) * 1.5 + 0.001
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
