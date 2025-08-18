//
//  ArtificialHorizon.swift
//  EarPilot
//
//  Created by Rogers George on 8/4/25.
//

import SwiftUI
import Spatial

struct ArtificialHorizon: View {

    let pitch: Angle2D
    let roll: Angle2D

    var body: some View {
        GeometryReader { g in
            let box = g.frame(in: .local)
            ZStack(alignment: .center) {
                Color.brown.brightness(-0.25)
                    .frame(width: box.width * 2, height: box.height * 3)
                    .position(x: box.midX, y: box.height * 2)
                    .transformEffect(.init(translationX: 0, y: pitch.angle.degrees * 4))
                    .rotationEffect(-roll.angle)

                pitchLadder(degreeScale: 4)
                    .transformEffect(.init(translationX: 0, y: pitch.angle.degrees * 4))
                    .rotationEffect(-roll.angle)

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
                .foregroundStyle(.tint)
            }
        }
        .background {
            Color.cyan.brightness(-0.125).ignoresSafeArea()
        }
        .mask {
            Rectangle().ignoresSafeArea()
        }
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
}

extension Angle2D {
    var angle: Angle {
        Angle(radians: self.radians)
    }
}
