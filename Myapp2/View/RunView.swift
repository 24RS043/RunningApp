//
//  RunView.swift
//  Myapp2
//
//  Created by  KoudaTakuma       on 2026/06/17.
//

import SwiftUI
import MapKit
import SwiftData

struct RunView: View {
    @Environment(\.modelContext) private var context
    @ObservedObject var locationManager: LocationManager
    @Query private var characters: [GameCharacter]
    @Query private var progresses: [GameProgress]
    @State private var earnedMessage: String?
    //LocationManagerというクラスのデータを監視して、変化したら画面を自動更新するための宣言
    var body: some View {
        ZStack{//奥行き方向
            Map(){ //地図表示
                UserAnnotation() //現在地マーク
                
                MapPolyline( //線を書く
                    coordinates: locationManager.route //移動したGPS履歴
                )
                .stroke(
                    Color.blue, //青線
                    lineWidth: 5 //太さ
                )
            }
            
            
            .mapControls{ //地図ボタン追加
                MapUserLocationButton() // 現在地へ戻るボタン
            }
            
            VStack  { //縦並び
                
                
                Spacer()
                
                HStack(spacing: 20) {
                    
                    VStack {
                        
                        Text("時間")
                            .font(.caption)//小さい文字にする
                            .foregroundColor(.gray)//文字色を灰色にする
                        
                        Text(
                            String(
                                format: "%d:%02d:%02d",
                                //%d：整数を表示
                                //2：2桁で表示する
                                //0：足りない桁を0で埋める
                                locationManager.elapsedTime / 3600,
                                (locationManager.elapsedTime % 3600) / 60,
                                locationManager.elapsedTime % 60
                            )
                        )
                        .font(.title2)
                        .bold()//太く
                    }
                    
                    VStack {
                        
                        Text("距離")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(
                            String(
                                format: "%.2f m",//少数２桁まで表示
                                locationManager.distance //移動距離
                            )
                        )
                        .font(.title2)
                        .bold()
                    }
                }
                .padding()
                .background(.ultraThinMaterial)//半透明
                .cornerRadius(25)
                .padding(.horizontal)//左右余白
                .padding(.bottom,20)
                
                HStack(spacing: 15) {
                    
                    Button("Start") {
                        locationManager.startRunning()
                        //Timer開始　距離リセット
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .font(.headline)
                    .disabled(locationManager.isRunning)
                    //走行中はおせない
                    
                    Button("Stop") {
                        locationManager.stopRunning()
                        //GPS,Timer停止
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .font(.headline)
                    .disabled(!locationManager.isRunning)
                }
                .padding(.horizontal)
                .padding(.bottom,40)
                
                
                //平均ペース表示
                if locationManager.distance > 0 {
                    let pacePerKm = Double(locationManager.elapsedTime) / (locationManager.distance / 1000)
                    //1kmあたりの時間
                    let paceMinutes = Int(pacePerKm) / 60
                    let paceSeconds = Int(pacePerKm) % 60
                    //分・秒に変換
                    
                    Text(
                        String(format: "平均ペース: %d'%02d\" /km", paceMinutes, paceSeconds)
                    )
                    .font(.title3)
                    .padding(.bottom, 10)
                }
            }
        }
        .onTapGesture { //画面タップ検知
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                //キーボードを閉じる
                to: nil,
                from: nil,
                for: nil
            )
        }
        .onChange(of: locationManager.lastRunQualified) { _, qualified in
            if qualified {
                checkRunBonus()
                locationManager.lastRunQualified = false
            }
        }
        .alert("ミッション達成！", isPresented: Binding(
            get: { earnedMessage != nil },
            set: { if !$0 { earnedMessage = nil } }
        )) {
            Button("OK") { earnedMessage = nil }
        } message: {
            Text(earnedMessage ?? "")
        }
    }
    private func checkRunBonus() {
        let character = characters.first ?? {
            let new = GameCharacter()
            context.insert(new)
            return new
        }()
        let progress = progresses.first ?? {
            let new = GameProgress()
            context.insert(new)
            return new
        }()
        
        let earned = MissionManager.checkRunBonus(
            character: character, progress: progress, totalDistance: locationManager.distance
        )
        
        if earned > 0 {
            try? context.save()
            earnedMessage = "ランニング達成！ \(earned) ポイント獲得！"
        }
    }
}

