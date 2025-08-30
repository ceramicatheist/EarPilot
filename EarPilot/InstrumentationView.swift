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

struct InstrumentationView: View {

    @State var tracker: PositionTracker

    init(tracker: PositionTracker) {
        self.tracker = tracker
    }

    var body: some View {
        ArtificialHorizon(pitch: tracker.pitch, roll: tracker.roll)
        .overlay(alignment: .top) {
            compass(heading: tracker.heading, degreeScale: 2)
                .foregroundStyle(.white)
        }
        .overlay(alignment: .trailing) {
            rocLadder(roc: tracker.rateOfClimb, fpmScale: 0.07)
                .foregroundStyle(.white)
        }
        .overlay(alignment: .bottom) {
            TurnCoordinator(coordination: tracker.coordination)
                .foregroundStyle(.white)
                .padding()
                .padding(.horizontal)
        }
        .accessibilityHidden(true)
        .dynamicTypeSize(.xxxLarge)
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
                        Rectangle().frame(width: 2, height: 5)
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
