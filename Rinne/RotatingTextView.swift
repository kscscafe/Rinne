//
//  RotatingTextView.swift
//  Rinne
//
//  Created by 杉崎康隆 on 2024/10/13.
//

import SwiftUI
import CoreMotion
import AVFoundation // 音声再生のためにインポート

struct RotatingTextView: View {
    @State private var outerAngle: Double = 0.0
    @State private var innerAngle: Double = 0.0
    @State private var innerMostAngle: Double = 0.0 // 内側のさらに内側の円用の角度
    @State private var scaleEffect: CGFloat = 1.0 // スケール効果の追加
    @State private var motionManager = CMMotionManager() // Core Motionマネージャ
    @State private var rotationAxis: (x: CGFloat, y: CGFloat, z: CGFloat) = (x: 0, y: 0, z: 0) // 回転軸
    
    // 外側の文字列
    @State private var outerText: [String]
    // 内側の文字列
    @State private var innerText: [String]
    // 次の文字列
    @State private var nextText: [String]
    // 次の次の文字列
    @State private var nextNextText: [String]
    
    @State private var outerCurrentIndex: Int = 0
    @State private var outerDisabledIndices: Set<Int> = []
    @State private var stringIndex: Int = 0
    @State private var textOpacity: Double = 0.0
    @State private var nextTextOpacity: Double = 0.0
    @State private var nextNextTextOpacity: Double = 0.0
    
    // 音声プレイヤーの定義
    @State private var audioPlayer: AVAudioPlayer?

    // 自動タップ用のタイマー
    @State private var autoTapTimer: Timer?
    @State private var isAutoTapping: Bool = false // 自動タップのフラグ
    
    // 直近のタップした文字を保存する配列
    @State private var tappedCharacters: [String] = []
    
    // 背景色のトグル
    @State private var isDarkMode: Bool = false
    
    let allStrings = StringData.strings // 文字列データを取得

    init() {
        let currentString = allStrings.first ?? ""
        _outerText = State(initialValue: currentString.map { String($0) }.shuffled())
        _innerText = State(initialValue: currentString.map { String($0) })
        _nextText = State(initialValue: Array(allStrings.dropFirst().first ?? "").map { String($0) }.shuffled())
        _nextNextText = State(initialValue: Array(allStrings.dropFirst(2).first ?? "").map { String($0) }.shuffled())
    }

    var body: some View {
        ZStack {
            // 背景色の設定
            Color(isDarkMode ? .black : .white)
                .edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                let outerRadius = CGFloat(min(geometry.size.width, geometry.size.height)) / 2 - 60
                let innerRadius = CGFloat(min(geometry.size.width, geometry.size.height)) / 4 - 10
                let nextRadius = CGFloat(min(geometry.size.width, geometry.size.height)) / 10 + 10
                let innerMostRadius = CGFloat(20 + 10)

                ZStack {
                    // 外側の円 (タップ可能、3D回転とスケール効果を追加)
                    createCircle(geometry: geometry, texts: outerText, radius: outerRadius, angle: outerAngle, fontSize: 35, textColor: isDarkMode ? .white : .black, isDisabled: outerDisabledIndices, opacity: textOpacity, rotationAxis: (x: 1, y: 0, z: 0), scaleEffect: scaleEffect) { index in
                        handleOuterTap(index: index)
                    }
                    
                    // 内側の円 (タップ不可、3D回転とスケール効果を追加)
                    createCircle(geometry: geometry, texts: innerText, radius: innerRadius, angle: innerAngle, fontSize: 20, textColor: isDarkMode ? .white.opacity(0.8) : .gray.opacity(0.8), isDisabled: Set(), opacity: textOpacity, rotationAxis: (x: 0, y: 1, z: 0), scaleEffect: scaleEffect, buttonAction: { _ in })
                    
                    // 次の文字列の円 (3D回転とスケール効果を追加)
                    createCircle(geometry: geometry, texts: nextText, radius: nextRadius, angle: innerMostAngle, fontSize: 10, textColor: isDarkMode ? .white.opacity(0.8) : .gray.opacity(0.8), isDisabled: Set(), opacity: nextTextOpacity, rotationAxis: (x: 0, y: 0, z: 1), scaleEffect: scaleEffect, buttonAction: { _ in })
                    
                    // 次の次の文字列の円 (3D回転とスケール効果を追加)
                    createCircle(geometry: geometry, texts: nextNextText, radius: innerMostRadius, angle: innerAngle, fontSize: 7, textColor: isDarkMode ? .white.opacity(0.8) : .gray.opacity(0.8), isDisabled: Set(), opacity: nextNextTextOpacity, rotationAxis: (x: 1, y: 1, z: 0), scaleEffect: scaleEffect, buttonAction: { _ in })
                }
                
                // 直近のタップした文字を表示
                VStack {
                    Text(tappedCharacters.prefix(15).joined()) // 直近15文字を表示
                        .font(.custom("Hiragino Mincho ProN", size: 20))
                        .foregroundColor(isDarkMode ? .white : .gray) // 背景に応じた文字色
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center) // 中央寄せ
                    Spacer() // 下部にスペースを追加
                }
            }
            
            // ボトムバー
            VStack {
                Spacer() // 上部にスペースを追加
                HStack {
                    Button(action: {
                        isAutoTapping.toggle() // 自動タップのトグル
                        if isAutoTapping {
                            startAutoTap() // 自動タップを開始
                        } else {
                            stopAutoTap() // 自動タップを停止
                        }
                    }) {
                        Image(systemName: isAutoTapping ? "stop.fill" : "play.fill") // アイコンを切り替え
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    Spacer() // アイコンの右側にスペースを追加
                    
                    Button(action: {
                        isDarkMode.toggle() // 背景色をトグル
                    }) {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill") // アイコンを切り替え
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .onAppear {
            startMotionUpdates() // モーションデータの取得を開始
            Timer.scheduledTimer(withTimeInterval: 1.00, repeats: true) { _ in
                withAnimation(.linear(duration: 1.00)) {
                    outerAngle -= 2.0 // 回転速度を変更
                    innerAngle += 1.0
                    innerMostAngle -= 1.5
                    scaleEffect = 1.0 + 0.1 * CGFloat(sin(outerAngle / 180.0 * .pi)) // スケール効果を動的に
                    resetAnglesIfNeeded()
                }
            }
            withAnimation(.easeIn(duration: 2.0)) {
                textOpacity = 1.0
                nextTextOpacity = 1.0
                nextNextTextOpacity = 1.0
            }
        }
    }

    // 自動タップ用のタイマー
    func startAutoTap() {
        autoTapTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // 文字がタップされていない場合、正しい順序でタップ
            if outerCurrentIndex < outerText.count {
                let correctChar = String(Array(allStrings[stringIndex])[outerCurrentIndex]) // 正しい文字を取得
                let indices = outerText.indices.filter { outerText[$0] == correctChar } // 同じ文字のインデックスを取得
                for index in indices {
                    if !outerDisabledIndices.contains(index) { // タップされていない場合
                        handleOuterTap(index: index) // 自動的にタップ
                        break // 一つタップしたら次へ
                    }
                }
            }
        }
    }

    // 自動タップを停止する関数
    func stopAutoTap() {
        autoTapTimer?.invalidate() // タイマーを停止
        autoTapTimer = nil
    }

    // モーションデータの更新開始
    func startMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
                if let motionData = motion {
                    // 傾きに応じて回転軸を更新
                    let roll = motionData.attitude.roll // x軸の回転
                    let pitch = motionData.attitude.pitch // y軸の回転
                    let yaw = motionData.attitude.yaw // z軸の回転
                    rotationAxis = (x: CGFloat(pitch * 180 / .pi), y: CGFloat(roll * 180 / .pi), z: CGFloat(yaw * 180 / .pi)) // ラジアンを度に変換
                }
            }
        }
    }

    func createCircle(geometry: GeometryProxy, texts: [String], radius: CGFloat, angle: Double, fontSize: CGFloat, textColor: Color, isDisabled: Set<Int>, opacity: Double, rotationAxis: (x: CGFloat, y: CGFloat, z: CGFloat), scaleEffect: CGFloat, buttonAction: @escaping (Int) -> Void) -> some View {
        ForEach(0..<texts.count, id: \.self) { index in
            let char = texts[index]
            let angleOffset = Double(index) * (360.0 / Double(texts.count))
            let xPosition = CGFloat(geometry.size.width / 2) + CGFloat(cos((angle + angleOffset) * .pi / 180)) * radius
            let yPosition = CGFloat(geometry.size.height / 2) + CGFloat(sin((angle + angleOffset) * .pi / 180)) * radius

            Button(action: {
                buttonAction(index)
            }) {
                Text(char)
                    .font(.custom("Hiragino Mincho ProN", size: fontSize))
                    .fontWeight(.bold)
                    .foregroundColor(isDisabled.contains(index) ? Color.gray.opacity(0.7) : textColor) // 濃さを調整
                    .opacity(opacity)
                    .shadow(color: isDisabled.contains(index) ? Color.gray.opacity(0.5) : Color.black.opacity(0.3), radius: 3, x: 2, y: 2) // 影を追加
            }
            .disabled(isDisabled.contains(index))
            .position(x: xPosition, y: yPosition)
            .rotation3DEffect(
                .degrees(30), // 3D回転角度
                axis: (x: rotationAxis.x, y: rotationAxis.y, z: rotationAxis.z)
            )
            .scaleEffect(scaleEffect) // スケール効果を追加
        }
    }

    func handleOuterTap(index: Int) {
        let correctChar = String(Array(allStrings[stringIndex])[outerCurrentIndex])
        
        // タップした文字が正しいか確認
        if outerText[index] == correctChar {
            if !outerDisabledIndices.contains(index) {
                outerDisabledIndices.insert(index) // タップした文字を無効化
                tappedCharacters.append(outerText[index]) // タップした文字を追加
                
                // 音声を再生
                playSound()

                // 15文字を超えた場合、最初の文字を削除
                if tappedCharacters.count > 15 {
                    tappedCharacters.removeFirst()
                }

                // 最後の文字がタップされたら次の文字列に切り替え
                outerCurrentIndex += 1 // 次の文字に進む
                
                if outerCurrentIndex == outerText.count {
                    // フェードアウトを開始
                    withAnimation(.easeIn(duration: 0.5)) {
                        textOpacity = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        loadNextString() // 次の文字列に切り替え
                    }
                }
            }
        }
    }

    func loadNextString() {
        stringIndex += 1

        if stringIndex >= allStrings.count {
            stringIndex = 0
        }

        let currentString = allStrings[stringIndex]
        outerText = currentString.map { String($0) }.shuffled()
        innerText = currentString.map { String($0) }
        nextText = Array(allStrings[(stringIndex + 1) % allStrings.count]).map { String($0) }.shuffled()
        nextNextText = Array(allStrings[(stringIndex + 2) % allStrings.count]).map { String($0) }.shuffled()

        outerCurrentIndex = 0
        outerDisabledIndices.removeAll()

        textOpacity = 0.0
        nextTextOpacity = 0.0
        nextNextTextOpacity = 0.0
        withAnimation(.easeIn(duration: 2.0)) {
            textOpacity = 1.0
            nextTextOpacity = 1.0;
            nextNextTextOpacity = 1.0;
        }
    }

    func resetAnglesIfNeeded() {
        if outerAngle <= -360 {
            outerAngle = 0
        }
        if innerAngle >= 360 {
            innerAngle = 0
        }
        if innerMostAngle <= -360 {
            innerMostAngle = 0
        }
    }
    
    func playSound() {
        guard let url = Bundle.main.url(forResource: "太鼓", withExtension: "mp3") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("音声再生エラー: \(error.localizedDescription)")
        }
    }
}

struct ContentView: View {
    var body: some View {
        RotatingTextView()
            .frame(width: 300, height: 300)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
