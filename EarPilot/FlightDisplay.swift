//
//  FlightDisplay.swift
//  EarPilot
//
//  Created by Rogers George on 1/19/24.
//

import SwiftUI
import CoreMotion
import Spatial

struct FlightDisplay: View {

    @StateObject var model = ModelController()

    var body: some View {
        VStack {
            Spacer()

            ArtificialHorizon(tracker: model.tracker)
                .aspectRatio(1, contentMode: .fit)

            Spacer()

            HStack {
                Spacer()
                Button("Zero pitch+roll") {
                    model.tracker.zero()
                }
                Spacer()
                Button("Beep") {
                    model.talker.beep()
                }
                Spacer()
            }
            .buttonStyle(.bordered)

            Spacer()

            Slider(value: Binding(get: {
                model.tracker.offAxisAngle.degrees
            }, set: {
                model.tracker.offAxisAngle = Angle2D(degrees: $0)
            }),
                   in: -45 ... 45,
                   step: 1)
            Text("off-axis angle: \(model.tracker.offAxisAngle.degrees, format: .number.rounded())º")
            Spacer()
        }
    }
}
