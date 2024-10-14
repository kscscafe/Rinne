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
                createOuterCircle(geometry: geometry, outerRadius: outerRadius)
                createInnerCircle(geometry: geometry, innerRadius: innerRadius)
                createNextCircle(geometry: geometry, nextRadius: nextRadius)
                createNextNextCircle(geometry: geometry, innerMostRadius: innerMostRadius)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.00, repeats: true) { _ in
                withAnimation(.linear(duration: 1.00)) {
                    outerAngle -= 1.5
                    innerAngle += 1.5
                    innerMostAngle -= 1.5
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
            withAnimation(.easeIn(duration: 2.0)) {
                textOpacity = 1.0
                nextTextOpacity = 1.0
                nextNextTextOpacity = 1.0 // 内側の円も徐々に表示
            }
        }
    }
    
    func createOuterCircle(geometry: GeometryProxy, outerRadius: CGFloat) -> some View {
        ForEach(0..<outerText.count, id: \.self) { index in
            let char = outerText[index]
            let angleOffset = Double(index) * (360.0 / Double(outerText.count))
            let xPosition = CGFloat(geometry.size.width / 2) + CGFloat(cos((outerAngle + angleOffset) * .pi / 180)) * outerRadius
            let yPosition = CGFloat(geometry.size.height / 2) + CGFloat(sin((outerAngle + angleOffset) * .pi / 180)) * outerRadius

            Button(action: {
                if char == String(Array(allStrings[stringIndex])[outerCurrentIndex]) {
                    outerDisabledIndices.insert(index)
                    outerCurrentIndex += 1

                    if outerCurrentIndex == outerText.count && innerCurrentIndex == innerText.count {
                        loadNextString()
                    }
                }
            }) {
                Text(char)
                    .font(.custom("Hiragino Mincho ProN", size: 35))
                    .fontWeight(.bold)
                    .foregroundColor(outerDisabledIndices.contains(index) ? Color.gray.opacity(0.5) : .primary)
                    .opacity(textOpacity)
            }
            .disabled(outerDisabledIndices.contains(index))
            .position(x: xPosition, y: yPosition)
        }
    }
    
    func createInnerCircle(geometry: GeometryProxy, innerRadius: CGFloat) -> some View {
        ForEach(0..<innerText.count, id: \.self) { index in
            let char = innerText[index]
            let angleOffset = Double(index) * (360.0 / Double(innerText.count))
            let xPosition = CGFloat(geometry.size.width / 2) + CGFloat(cos((innerAngle + angleOffset) * .pi / 180)) * innerRadius
            let yPosition = CGFloat(geometry.size.height / 2) + CGFloat(sin((innerAngle + angleOffset) * .pi / 180)) * innerRadius
            
            Button(action: {
                if char == String(Array(allStrings[stringIndex])[outerText.count + innerCurrentIndex]) {
                    innerDisabledIndices.insert(index)
                    innerCurrentIndex += 1

                    if outerCurrentIndex == outerText.count && innerCurrentIndex == innerText.count {
                        loadNextString()
                    }
                }
            }) {
                Text(char)
                    .font(.custom("Hiragino Mincho ProN", size: 35))
                    .fontWeight(.bold)
                    .foregroundColor(innerDisabledIndices.contains(index) ? Color.gray.opacity(0.5) : .primary)
                    .opacity(textOpacity)
            }
            .disabled(innerDisabledIndices.contains(index))
            .position(x: xPosition, y: yPosition)
        }
    }
    
    func createNextCircle(geometry: GeometryProxy, nextRadius: CGFloat) -> some View {
        ForEach(0..<nextText.count, id: \.self) { index in
            let char = nextText[index]
            let angleOffset = Double(index) * (360.0 / Double(nextText.count))
            let xPosition = CGFloat(geometry.size.width / 2) + CGFloat(cos((innerMostAngle + angleOffset) * .pi / 180)) * nextRadius
            let yPosition = CGFloat(geometry.size.height / 2) + CGFloat(sin((innerMostAngle + angleOffset) * .pi / 180)) * nextRadius
            
            Text(char)
                .font(.custom("Hiragino Mincho ProN", size: 10))
                .foregroundColor(Color.black.opacity(0.8))
                .opacity(nextTextOpacity)
                .position(x: xPosition, y: yPosition)
        }
    }
    
    func createNextNextCircle(geometry: GeometryProxy, innerMostRadius: CGFloat) -> some View {
        ForEach(0..<nextNextText.count, id: \.self) { index in
            let char = nextNextText[index]
            let angleOffset = Double(index) * (360.0 / Double(nextNextText.count))
            let xPosition = CGFloat(geometry.size.width / 2) + CGFloat(cos((innerAngle + angleOffset) * .pi / 180)) * innerMostRadius
            let yPosition = CGFloat(geometry.size.height / 2) + CGFloat(sin((innerAngle + angleOffset) * .pi / 180)) * innerMostRadius
            
            Text(char)
                .font(.custom("Hiragino Mincho ProN", size: 7))
                .foregroundColor(Color.black.opacity(0.8))
                .opacity(nextNextTextOpacity) // アニメーションを適用
                .position(x: xPosition, y: yPosition)
        }
    }

    // 次の文字列を設定
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
        nextNextText = Array(allStrings[(stringIndex + 2) % allStrings.count]).map { String($0) }.shuffled() // 次の次の文字列

        outerCurrentIndex = 0
        innerCurrentIndex = 0
        outerDisabledIndices.removeAll()
        innerDisabledIndices.removeAll()
        
        // アニメーションで透明度をリセットして徐々に表示
        textOpacity = 0.0
        nextTextOpacity = 0.0
        nextNextTextOpacity = 0.0 // 内側の円もリセット
        withAnimation(.easeIn(duration: 2.0)) {
            textOpacity = 1.0
            nextTextOpacity = 1.0
            nextNextTextOpacity = 1.0 // 内側の円も徐々に表示
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
