//
//  TurnCoordinator.swift
//  EarPilot
//
//  Created by Rogers George on 4/22/24.
//

import SwiftUI

@MainActor
struct TurnCoordinator: View {
    var coordination: Double // negative is left

    let radius = 16.0

    var body: some View {

        GeometryReader { g in
            let box = g.frame(in: .local)
            let arc = Path {
                $0.move(to: CGPoint(x: box.minX + radius, y: box.minY + radius))
                $0.addQuadCurve(to: CGPoint(x: box.midX, y: box.maxY - radius),
                                control: CGPoint(x: (box.minX + box.midX) / 2.0, y: box.maxY - radius))
                $0.addQuadCurve(to: CGPoint(x: box.maxX - radius, y: box.minY + radius),
                                control: CGPoint(x: (box.midX + box.maxX) / 2.0, y: box.maxY - radius))
            }

            arc.strokedPath(.init(lineWidth: radius * 2, lineCap: .round)).strokedPath(.init(lineWidth: 1))

            Path {
                $0.move(to: CGPoint(x: box.midX - radius, y: box.maxY))
                $0.addLine(to: CGPoint(x: box.midX - radius, y: box.maxY - radius * 2))
                $0.move(to: CGPoint(x: box.midX + radius, y: box.maxY))
                $0.addLine(to: CGPoint(x: box.midX + radius, y: box.maxY - radius * 2))
            }.strokedPath(.init(lineWidth: 1))

            let t = coordination.clamped(to: -0.5...0.5) + 0.5
            let trim = arc.trimmedPath(from: (t - 0.01).clamped(to: 0...1),
                                       to: (t + 0.01).clamped(to: 0...1)).boundingRect

            Path {
                $0.addArc(center: CGPoint(x: trim.midX, y: trim.midY),
                          radius: radius,
                          startAngle: .zero,
                          endAngle: .radians(.pi * 2),
                          clockwise: true)
            }.fill()
        }
        .frame(maxHeight: 64)
    }
}

extension BinaryFloatingPoint {
    func clamped(to range: ClosedRange<Self>) -> Self {
        (self...self).clamped(to: range).lowerBound
    }
}
