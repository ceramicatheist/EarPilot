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
            ArtificialHorizon(tracker: model.tracker)
                .aspectRatio(1, contentMode: .fit)

            Spacer()

            Toggle(isOn: model.$shouldSpeakBank, label: {
                Text("Speak Bank Angles")
            })

            Toggle(isOn: model.$shouldBeepPitch, label: {
                Text("Beep Pitch Angle")
            })

            Toggle(isOn: model.$shouldSpeakCompass, label: {
                Text("Speak Compass Points")
            })
            
            HStack {
                Text("using voice: \(Talker.voice?.name ?? "unspecified")")
                Spacer()
            }

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
            Button("Zero pitch+roll") {
                model.tracker.zero()
            }
            .buttonStyle(.bordered)

            Spacer()
            Spacer()
        }
        .padding()
    }
}
