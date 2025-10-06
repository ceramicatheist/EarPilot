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
        .overlay {
            VStack(spacing: 0) {
                compass(heading: tracker.heading, degreeScale: 2)
                    .foregroundStyle(.white)
                HStack(spacing: 0) {
                    speedTape(knots: 0, scale: 0)
                    Spacer()
                    altimeter(feet: tracker.altitude,
                              fpm: tracker.rateOfClimb, scale: 0.4)
                }
                TurnCoordinator(coordination: tracker.coordination)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 2)
                    .padding(.horizontal)
            }
        }
        .accessibilityHidden(true)
        .dynamicTypeSize(.xxxLarge)
    }

    @ViewBuilder func compass(heading: Angle2D, degreeScale: Double) -> some View
    {
        VStack {
            ZStack(alignment: .center) {
                Color.clear.frame(maxHeight: 1)
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
        .clipped()
    }

    @ViewBuilder func speedTape(knots: Double, scale: Double) -> some View {

    }

    @ViewBuilder func altimeter(feet: Double, fpm: Double, scale: Double) -> some View
    {
        HStack(spacing: 0) {
            Image(systemName: "chevron.right").overlay(alignment: .top) {
                if fpm > 10 {
                    Image(systemName: "chevron.compact.up")
                        .offset(y: -fpm * scale)
                }
            }
            .overlay(alignment: .bottom) {
                if fpm < -10 {
                    Image(systemName: "chevron.compact.down")
                        .offset(y: -fpm * scale)
                }
            }
            ZStack(alignment: .leading) {
                ForEach(Array(stride(from: 0, through: 10000, by: 100)), id: \.self) { ft in
                    let thousands = (ft / 1000).formatted()
                    let hundreds = (ft % 1000).formatted(.number.precision(.integerLength(3)))

                    (Text(thousands).font(.footnote.bold()) + Text(hundreds).font(.caption2))
                        .monospacedDigit()
                        .offset(y: (Double(-ft) + feet) * scale)
                        .padding(.trailing, 2)
                        .dynamicTypeSize(.xLarge)
                }
            }
            Color.clear.frame(maxWidth: 1)
        }
        .clipped()
    }
}
