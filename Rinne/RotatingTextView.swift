//
//  RotatingTextView.swift
//  Rinne
//
//  Created by 杉崎康隆 on 2024/10/13.
//

import SwiftUI

struct RotatingTextView: View {
    @State private var outerAngle: Double = 0.0
    @State private var innerAngle: Double = 0.0
    @State private var innerMostAngle: Double = 0.0 // 内側のさらに内側の円用の角度
    @State private var outerText: [String]
    @State private var innerText: [String]
    @State private var nextText: [String] // 次の文字列用
    @State private var nextNextText: [String] // 次の次の文字列用
    @State private var outerCurrentIndex: Int = 0
    @State private var innerCurrentIndex: Int = 0
    @State private var outerDisabledIndices: Set<Int> = []
    @State private var innerDisabledIndices: Set<Int> = []
    @State private var stringIndex: Int = 0  // 現在表示中の文字列のインデックス
    @State private var textOpacity: Double = 0.0 // アニメーションのためのopacity
    @State private var nextTextOpacity: Double = 0.0 // 次の文字列の透明度
    @State private var nextNextTextOpacity: Double = 0.0 // 次の次の文字列の透明度

    let allStrings = StringData.strings
    
    init() {
        let currentString = allStrings.first ?? ""
        let middleIndex = currentString.count / 2
        let outerPart = String(currentString.prefix(middleIndex))
        let innerPart = String(currentString.suffix(from: currentString.index(currentString.startIndex, offsetBy: middleIndex)))
        _outerText = State(initialValue: outerPart.map { String($0) }.shuffled())
        _innerText = State(initialValue: innerPart.map { String($0) }.shuffled())
        _nextText = State(initialValue: Array(allStrings.dropFirst().first ?? "").map { String($0) }.shuffled())
        _nextNextText = State(initialValue: Array(allStrings.dropFirst(2).first ?? "").map { String($0) }.shuffled())
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                createCircle(geometry: geometry, textArray: outerText, angle: outerAngle, radius: min(geometry.size.width, geometry.size.height) / 2 - 60, opacity: textOpacity, fontSize: 35, isButton: true, disabledIndices: $outerDisabledIndices, currentIndex: $outerCurrentIndex, totalCount: outerText.count)
                createCircle(geometry: geometry, textArray: innerText, angle: innerAngle, radius: min(geometry.size.width, geometry.size.height) / 4 - 10, opacity: textOpacity, fontSize: 35, isButton: true, disabledIndices: $innerDisabledIndices, currentIndex: $innerCurrentIndex, totalCount: outerText.count + innerText.count)
                createCircle(geometry: geometry, textArray: nextText, angle: innerMostAngle, radius: min(geometry.size.width, geometry.size.height) / 10 + 10, opacity: nextTextOpacity, fontSize: 10, isButton: false)
                createCircle(geometry: geometry, textArray: nextNextText, angle: innerAngle, radius: 25, opacity: nextNextTextOpacity, fontSize: 6, isButton: false)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.00, repeats: true) { _ in
                withAnimation(.linear(duration: 1.00)) {
                    outerAngle -= 1.5
                    innerAngle += 1.5
                    innerMostAngle -= 1.5
                    if outerAngle <= -360 { outerAngle = 0 }
                    if innerAngle >= 360 { innerAngle = 0 }
                    if innerMostAngle <= -360 { innerMostAngle = 0 }
                }
            }
            withAnimation(.easeIn(duration: 2.0)) {
                textOpacity = 1.0
                nextTextOpacity = 1.0
                nextNextTextOpacity = 1.0
            }
        }
    }

    // 共通の円を作成する関数
    func createCircle(geometry: GeometryProxy, textArray: [String], angle: Double, radius: CGFloat, opacity: Double, fontSize: CGFloat, isButton: Bool, disabledIndices: Binding<Set<Int>>? = nil, currentIndex: Binding<Int>? = nil, totalCount: Int = 0) -> some View {
        ForEach(0..<textArray.count, id: \.self) { index in
            let char = textArray[index]
            let angleOffset = Double(index) * (360.0 / Double(textArray.count))
            let xPosition = CGFloat(geometry.size.width / 2) + CGFloat(cos((angle + angleOffset) * .pi / 180)) * radius
            let yPosition = CGFloat(geometry.size.height / 2) + CGFloat(sin((angle + angleOffset) * .pi / 180)) * radius

            if isButton {
                Button(action: {
                    if char == String(Array(allStrings[stringIndex])[currentIndex?.wrappedValue ?? 0]) {
                        disabledIndices?.wrappedValue.insert(index)
                        currentIndex?.wrappedValue += 1

                        if currentIndex?.wrappedValue == totalCount {
                            loadNextString()
                        }
                    }
                }) {
                    Text(char)
                        .font(.custom("Hiragino Mincho ProN", size: fontSize))
                        .fontWeight(.bold)
                        .foregroundColor(disabledIndices?.wrappedValue.contains(index) == true ? Color.black.opacity(0.5) : .primary)
                        .opacity(opacity)
                }
                .disabled(disabledIndices?.wrappedValue.contains(index) == true)
                .position(x: xPosition, y: yPosition)
            } else {
                Text(char)
                    .font(.custom("Hiragino Mincho ProN", size: fontSize))
                    .foregroundColor(Color.gray.opacity(0.8))
                    .opacity(opacity)
                    .position(x: xPosition, y: yPosition)
            }
        }
    }

    // 次の文字列を設定
    func loadNextString() {
        stringIndex += 1
        if stringIndex >= allStrings.count { stringIndex = 0 }
        
        let currentString = allStrings[stringIndex]
        let middleIndex = currentString.count / 2
        let outerPart = String(currentString.prefix(middleIndex))
        let innerPart = String(currentString.suffix(from: currentString.index(currentString.startIndex, offsetBy: middleIndex)))
        outerText = outerPart.map { String($0) }.shuffled()
        innerText = innerPart.map { String($0) }.shuffled()
        nextText = Array(allStrings[(stringIndex + 1) % allStrings.count]).map { String($0) }.shuffled()
        nextNextText = Array(allStrings[(stringIndex + 2) % allStrings.count]).map { String($0) }.shuffled()
        
        outerCurrentIndex = 0
        innerCurrentIndex = 0
        outerDisabledIndices.removeAll()
        innerDisabledIndices.removeAll()
        
        textOpacity = 0.0
        nextTextOpacity = 0.0
        nextNextTextOpacity = 0.0
        withAnimation(.easeIn(duration: 2.0)) {
            textOpacity = 1.0
            nextTextOpacity = 1.0
            nextNextTextOpacity = 1.0
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
