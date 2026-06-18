//
//  RunView.swift
//  Myapp2
//
//  Created by  KoudaTakuma       on 2026/06/17.
//

import SwiftUI
import MapKit

struct RunView: View {
    @ObservedObject var locationManager: LocationManager
    @AppStorage("weight") var weight = ""
    
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
                
                TextField("体重(kg)", text: $weight) //体重入力欄
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)//キーボードの種類変更
                    .submitLabel(.done) //数字専用キーボード
                    .padding()
                
                Spacer()
                
                HStack(spacing: 20) {
                    
                    VStack {
                        
                        Text("時間")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(
                            String(
                                format: "%d:%02d:%02d",
                                locationManager.elapsedTime / 3600,
                                (locationManager.elapsedTime % 3600) / 60,
                                locationManager.elapsedTime % 60
                            )
                        )
                        .font(.title2)
                        .bold()
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
                }
                .padding(.horizontal)
                .padding(.bottom,40)
                
                if let weightValue = Double(weight) {// 文字列を数字に変換
                    
                    let calories = weightValue * (locationManager.distance / 1000)
                    
                    
                    Text(
                        String(
                            format: "消費カロリー: %.1f kcal",
                            calories
                        )
                    )
                    .font(.title3)
                    .padding(.bottom, 10)
                }
                if locationManager.distance > 0 {
                    let pacePerKm = Double(locationManager.elapsedTime) / (locationManager.distance / 1000)
                    let paceMinutes = Int(pacePerKm) / 60
                    let paceSeconds = Int(pacePerKm) % 60
                    
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
    }
}
