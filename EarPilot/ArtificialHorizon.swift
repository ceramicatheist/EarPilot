//
//  ArtificialHorizon.swift
//  EarPilot
//
//  Created by Rogers George on 1/20/24.
//

import SwiftUI
import Spatial

struct ArtificialHorizon: View {

    private(set) var tracker: PositionTracker

    init(tracker: PositionTracker) {
        self.tracker = tracker
    }

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
            let q = tracker.attitude.quaternion
            let dfmt = FloatingPointFormatStyle<Double>()
                .precision(.integerAndFractionLength(integer: 3, fraction: 0))
                .sign(strategy: .always())
            let qfmt = FloatingPointFormatStyle<Double>()
                .precision(.integerAndFractionLength(integer: 1, fraction: 2))
                .sign(strategy: .always())
            Text("""
                pitch: \(tracker.pitch.degrees.formatted(dfmt))
                 roll: \(tracker.roll.degrees.formatted(dfmt))
                  yaw: \(tracker.yaw.degrees.formatted(dfmt))
                quaternion: [\(q.real.formatted(qfmt)) \(q.imag.x.formatted(qfmt)) \
                \(q.imag.y.formatted(qfmt)) \(q.imag.z.formatted(qfmt))]
                """)
            .monospaced()
            .foregroundStyle(.yellow)
        }
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
        .foregroundStyle(.green)
        .transformEffect(.init(translationX: 0, y: -angle.degrees * 2)) // all wrong
    }
}

extension Angle2D {
    var angle: Angle {
        Angle(radians: self.radians)
    }
}
