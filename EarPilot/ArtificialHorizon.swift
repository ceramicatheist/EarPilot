//
//  ArtificialHorizon.swift
//  EarPilot
//
//  Created by Rogers George on 1/20/24.
//

import SwiftUI
import Spatial

struct ArtificialHorizon: View {

    @ObservedObject private(set) var tracker: PositionTracker

    init(tracker: PositionTracker) {
        self.tracker = tracker
    }

    let dfmt = FloatingPointFormatStyle<Double>()
        .precision(.integerAndFractionLength(integer: 3, fraction: 0))

    var body: some View {
        GeometryReader { g in
            let box = g.frame(in: .local)
            ZStack(alignment: .center) {
                Color.brown
                    .frame(width: box.width * 2, height: box.height)
                    .position(x: box.midX, y: box.maxY)
                ladder(tracker.pitch.angle)
            }
            .rotationEffect(-tracker.roll.angle)
        }
        .background(.cyan)
        .clipped()
        .overlay(alignment: .topLeading) {
            Text("heading: \(tracker.heading.degrees.formatted(dfmt))º")
            .monospaced()
            .foregroundStyle(.red)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder func ladder(_ angle: Angle) -> some View
    {
        Text("""
            ----
            ---
            --
            -
            0
            +
            ++
            +++
            ++++
            """)
        .multilineTextAlignment(.center)
        .foregroundStyle(.yellow)
        .transformEffect(.init(translationX: 0, y: -angle.degrees * 4)) // all wrong
    }
}

extension Angle2D {
    var angle: Angle {
        Angle(radians: self.radians)
    }
}
