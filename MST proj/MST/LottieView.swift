//
//  LottieView.swift
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
import Lottie

struct LottieView: UIViewRepresentable {
    let animationName: String
    var loopMode: LottieLoopMode = .playOnce
    var animationSpeed: CGFloat = 1.0
    @Binding var isPlaying: Bool

    func makeUIView(context: Context) -> some UIView {
        let container = UIView()
        let animationView = LottieAnimationView(name: animationName)
        animationView.loopMode = loopMode
        animationView.animationSpeed = animationSpeed
        animationView.contentMode = .scaleAspectFit
        animationView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        context.coordinator.animationView = animationView
        return container
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        guard let animationView = context.coordinator.animationView else { return }

        if isPlaying {
            animationView.play { finished in
                if finished {
                    DispatchQueue.main.async {
                        isPlaying = false
                    }
                }
            }
        } else {
            animationView.stop()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var animationView: LottieAnimationView?
    }
}
