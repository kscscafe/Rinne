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
    @State private var textOpacity: Double = 0.0 // 外側の円のアニメーションのためのopacity
    @State private var nextTextOpacity: Double = 0.0 // 次の円の透明度
    @State private var nextNextTextOpacity: Double = 0.0 // 内側の円（次の次の文字列）の透明度

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
            let outerRadius = CGFloat(min(geometry.size.width, geometry.size.height)) / 2 - 60
            let innerRadius = CGFloat(min(geometry.size.width, geometry.size.height)) / 4 - 10
            let nextRadius = CGFloat(min(geometry.size.width, geometry.size.height)) / 10 + 10
            let innerMostRadius = CGFloat(20 + 10) // 内側の円の半径
            
            ZStack {
                createCircle(geometry: geometry, texts: outerText, radius: outerRadius, angle: outerAngle, fontSize: 35, textColor: .primary, isDisabled: outerDisabledIndices, opacity: textOpacity) { index in
                    handleOuterTap(index: index)
                }
                createCircle(geometry: geometry, texts: innerText, radius: innerRadius, angle: innerAngle, fontSize: 35, textColor: .primary, isDisabled: innerDisabledIndices, opacity: textOpacity) { index in
                    handleInnerTap(index: index)
                }
                createCircle(geometry: geometry, texts: nextText, radius: nextRadius, angle: innerMostAngle, fontSize: 10, textColor: Color.gray.opacity(0.8), isDisabled: Set(), opacity: nextTextOpacity, buttonAction: { _ in })
                createCircle(geometry: geometry, texts: nextNextText, radius: innerMostRadius, angle: innerAngle, fontSize: 7, textColor: Color.gray.opacity(0.8), isDisabled: Set(), opacity: nextNextTextOpacity, buttonAction: { _ in })
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.00, repeats: true) { _ in
                withAnimation(.linear(duration: 1.00)) {
                    outerAngle -= 1.5
                    innerAngle += 1.5
                    innerMostAngle -= 1.5
                    resetAnglesIfNeeded()
                }
            }
            withAnimation(.easeIn(duration: 2.0)) {
                textOpacity = 1.0
                nextTextOpacity = 1.0
                nextNextTextOpacity = 1.0 // 内側の円も徐々に表示
            }
        }
    }

    func createCircle(geometry: GeometryProxy, texts: [String], radius: CGFloat, angle: Double, fontSize: CGFloat, textColor: Color, isDisabled: Set<Int>, opacity: Double, buttonAction: @escaping (Int) -> Void) -> some View {
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
                    .fontWeight(.bold) // 太字を再追加
                    .foregroundColor(isDisabled.contains(index) ? Color.gray.opacity(0.5) : textColor)
                    .opacity(opacity) // 透明度の設定を保持
            }
            .disabled(isDisabled.contains(index))
            .position(x: xPosition, y: yPosition)
        }
    }

    func handleOuterTap(index: Int) {
        if outerText[index] == String(Array(allStrings[stringIndex])[outerCurrentIndex]) {
            outerDisabledIndices.insert(index)
            outerCurrentIndex += 1

            if outerCurrentIndex == outerText.count && innerCurrentIndex == innerText.count {
                loadNextString()
            }
        }
    }

    func handleInnerTap(index: Int) {
        if innerText[index] == String(Array(allStrings[stringIndex])[outerText.count + innerCurrentIndex]) {
            innerDisabledIndices.insert(index)
            innerCurrentIndex += 1

            if outerCurrentIndex == outerText.count && innerCurrentIndex == innerText.count {
                loadNextString()
            }
        }
    }

    func loadNextString() {
        stringIndex += 1

        if stringIndex >= allStrings.count {
            stringIndex = 0
        }

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
