//
//  ArtificialHorizon.swift
//  EarPilot
//
//  Created by Rogers George on 1/20/24.
//

import SwiftUI
import Spatial

let dfmt = FloatingPointFormatStyle<Double>()
    .precision(.integerAndFractionLength(integer: 3, fraction: 0)).sign(strategy: .always())

struct ArtificialHorizon: View {

    @ObservedObject private(set) var tracker: PositionTracker

    init(tracker: PositionTracker) {
        self.tracker = tracker
    }

    var body: some View {
        GeometryReader { g in
            let box = g.frame(in: .local)
            ZStack(alignment: .center) {
                Color.brown
                    .frame(width: box.width * 2, height: box.height * 3)
                    .position(x: box.midX, y: box.height * 2)
                    .transformEffect(.init(translationX: 0, y: tracker.pitch.angle.degrees * 4))
                    .rotationEffect(-tracker.roll.angle)

                pitchLadder(degreeScale: 4)
                    .transformEffect(.init(translationX: 0, y: tracker.pitch.angle.degrees * 4))
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
        .overlay(alignment: .top) {
            compass(heading: tracker.heading, degreeScale: 2)
                .foregroundStyle(.white)
        }
        .overlay(alignment: .trailing) {
            rocLadder(roc: tracker.rateOfClimb, fpmScale: 0.07)
                .foregroundStyle(.white)
        }
        .overlay(alignment: .bottom) {
            HStack {
//                Text("Z: \(tracker.zeroAttitude?.rpy ?? "?")")
//                Spacer()
                Text("P:\(tracker.pitch.degrees.formatted(dfmt)) R:\(tracker.roll.degrees.formatted(dfmt)) Y:\(tracker.yaw.degrees.formatted(dfmt))")
            }
            .foregroundStyle(.white)
            .monospaced()
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder func pitchLadder(degreeScale: Double) -> some View
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

    @ViewBuilder func compass(heading: Angle2D, degreeScale: Double) -> some View
    {
        VStack {
            ZStack(alignment: .center) {
                ForEach(Array(stride(from: -180, through: 540, by: 15)), id:\.self) { deg in
                    VStack(spacing: 0) {
                        switch deg {
                        case 0, 360:
                            Text("N").bold()
                                .font(.caption)
                        case 90, 450:
                            Text("E").bold()
                                .font(.caption)
                        case 180, -180:
                            Text("S").bold()
                                .font(.caption)
                        case 270, -90:
                            Text("W").bold()
                                .font(.caption)
                        case _ where (deg + 360) % 10 != 0:
                            Text(" ").font(.footnote)
                        default:
                            Text(((deg + 360) % 360).description)
                                .font(.caption2)
                        }
                        Rectangle().frame(width: 1, height: 5)
                    }
                    .offset(x: Double(deg) * degreeScale)
                }
            }
            .offset(x: -heading.degrees * degreeScale)
            Image(systemName: "chevron.up")
        }
    }

    @ViewBuilder func rocLadder(roc: Double, fpmScale: Double) -> some View
    {
        HStack(spacing: -4) {
            Image(systemName: "chevron.right")
                .offset(y: -roc * fpmScale)
            ZStack(alignment: .trailing) {
                ForEach(Array(stride(from: -2000, through: 2000, by: 500)), id: \.self) { fpm in
                    Text((fpm / 100).description).font(.footnote)
                        .offset(y: Double(-fpm) * fpmScale)
                        .padding(.trailing, 2)
                }
            }
        }
    }
}

extension Angle2D {
    var angle: Angle {
        Angle(radians: self.radians)
    }
}

extension Rotation3D {

    var rpy: String {
        let ea = self.eulerAngles(order: .zxy).angles * 57.29577951
        return "x\(ea.x.formatted(dfmt)) y\(ea.y.formatted(dfmt)) z\(ea.z.formatted(dfmt))"
    }
}
