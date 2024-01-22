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
        let angles = tracker.attitude.eulerAngles(order: .xyz)
        let pitch = Angle(radians: angles.angles.x)
        let roll = Angle(radians: angles.angles.y)
        GeometryReader { g in
            let box = g.frame(in: .local)
            ZStack(alignment: .center) {
                Color.brown
                    .frame(width: box.width * 2, height: box.height)
                    .position(x: box.midX, y: box.maxY)
                ladder(pitch)
            }
            .rotationEffect(-roll)
        }
        .background(.cyan)
        .clipped()
        .overlay(alignment: .topLeading) {
            Text("""
                pitch: \(pitch.degrees.rounded().formatted())
                 roll: \(roll.degrees.rounded().formatted())
                """)
            .foregroundStyle(.green)
        }
    }

    @ViewBuilder func ladder(_ angle: Angle) -> some View
    {
        Text("""
            -20
            -15
            -10
            -5
             0
             5
             10
             15
             20
            """)
        .multilineTextAlignment(.center)
        .foregroundStyle(.yellow)
        .transformEffect(.init(translationX: 0, y: -angle.degrees * 2)) // all wrong
    }
}
