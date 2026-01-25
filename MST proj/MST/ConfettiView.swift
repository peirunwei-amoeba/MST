//
//  ConfettiView.swift
//  MST
//
//  Copyright © 2025 Pei Runwei. All rights reserved.
//
//  This Source Code Form is subject to the terms of the PolyForm Strict
//  License 1.0.0. You may not use, modify, or distribute this file except
//  in compliance with the License. A copy of the License is located at:
//  https://polyformproject.org/licenses/strict/1.0.0
//
//  Required Notice: Copyright Pei Runwei (https://github.com/peirunwei-amoeba)
//

import SwiftUI

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var isAnimating = false

    let particleCount: Int

    init(particleCount: Int = 100) {
        self.particleCount = particleCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
                startAnimation()
            }
        }
        .allowsHitTesting(false)
    }

    private func generateConfetti(in size: CGSize) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan, .mint]
        let shapes: [ConfettiShape] = [.circle, .rectangle, .triangle]

        for _ in 0..<particleCount {
            let piece = ConfettiPiece(
                x: CGFloat.random(in: 0...size.width),
                y: -CGFloat.random(in: 20...100),
                targetY: size.height + 100,
                rotation: Double.random(in: 0...360),
                targetRotation: Double.random(in: 360...1080),
                scale: CGFloat.random(in: 0.5...1.2),
                color: colors.randomElement()!,
                shape: shapes.randomElement()!,
                delay: Double.random(in: 0...0.5),
                horizontalDrift: CGFloat.random(in: -80...80)
            )
            confettiPieces.append(piece)
        }
    }

    private func startAnimation() {
        withAnimation(.easeIn(duration: 4)) {
            isAnimating = true
            for i in confettiPieces.indices {
                confettiPieces[i].y = confettiPieces[i].targetY
                confettiPieces[i].x += confettiPieces[i].horizontalDrift
                confettiPieces[i].rotation = confettiPieces[i].targetRotation
            }
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var targetY: CGFloat
    var rotation: Double
    var targetRotation: Double
    var scale: CGFloat
    var color: Color
    var shape: ConfettiShape
    var delay: Double
    var horizontalDrift: CGFloat
}

enum ConfettiShape {
    case circle
    case rectangle
    case triangle
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece

    var body: some View {
        confettiShapeView
            .frame(width: 10 * piece.scale, height: 10 * piece.scale)
            .rotationEffect(.degrees(piece.rotation))
            .position(x: piece.x, y: piece.y)
            .animation(
                .easeIn(duration: 3 + piece.delay)
                    .delay(piece.delay),
                value: piece.y
            )
    }

    @ViewBuilder
    private var confettiShapeView: some View {
        switch piece.shape {
        case .circle:
            Circle().fill(piece.color)
        case .rectangle:
            Rectangle().fill(piece.color)
        case .triangle:
            Triangle().fill(piece.color)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3)
        ConfettiView()
    }
}
