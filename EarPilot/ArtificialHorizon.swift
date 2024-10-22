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
                    .frame(width: box.width * 2, height: box.height * 3)
                    .position(x: box.midX, y: box.height * 2)
                    .transformEffect(.init(translationX: 0, y: tracker.pitch.angle.degrees * 4))
                    .rotationEffect(-tracker.roll.angle)

                ladder(degreeScale: 4)
                    .rotationEffect(-tracker.roll.angle)

                Path {
                    $0.move(to: CGPoint(x: -box.width/4, y: 0))
                    $0.addArc(center: .zero, radius: 15, startAngle: .radians(.pi), endAngle: .radians(3 * .pi / 4), clockwise: true)
                    $0.move(to: CGPoint(x: box.width/4, y: 0))
                    $0.addArc(center: .zero, radius: 15, startAngle: .zero, endAngle: .radians(.pi / 4), clockwise: false)
                    $0.move(to: .zero)
                    $0.addEllipse(in: CGRect(x: -3, y: -3, width: 6, height: 6))
                }
                .strokedPath(.init(lineWidth: 2))
                .frame(width: 1, height: 1, alignment: .center)
                .foregroundStyle(.yellow)
            }
        }
        .background(.cyan)
        .clipped()
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading) {
                Text("heading: \(tracker.heading.degrees.formatted(dfmt))º")
                Text("rate of climb: \(tracker.rateOfClimb.formatted(.number.sign(strategy: .always()).precision(.fractionLength(0...0)))) ft/min")
            }
            .monospaced()
            .foregroundStyle(.pink)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder func ladder(degreeScale: Double) -> some View
    {
        ZStack(alignment: .center) {
            ForEach([10, 20, 30], id: \.self) { deg in
                HStack {
                    Text(deg.description).hidden()
                    Rectangle().frame(width: Double(deg * 2), height: 1)
                    Text(deg.description)
                }
                .offset(y: -Double(deg) * degreeScale)

                Rectangle().frame(width: Double(deg / 2), height: 1)
                    .offset(y: -Double(deg - 5) * degreeScale)

                HStack {
                    Text(deg.description).hidden()
                    Rectangle().frame(width: Double(deg * 2), height: 1)
                    Text(deg.description)
                }
                .offset(y: Double(deg) * degreeScale)

                Rectangle().frame(width: Double(deg / 2), height: 1)
                    .offset(y: Double(deg - 5) * degreeScale)
            }
            .font(.footnote)
        }
        .foregroundStyle(.white)
    }
}

extension Angle2D {
    var angle: Angle {
        Angle(radians: self.radians)
    }
}
