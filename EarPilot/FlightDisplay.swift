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
    @State var dummy = false

    var body: some View {
        VStack {
            ArtificialHorizon(tracker: model.tracker)
                .aspectRatio(1, contentMode: .fit)
                .overlay(alignment: .bottom) {
                    TurnCoordinator(coordination: model.tracker.coordination)
                        .padding()
                }

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

            LabeledContent {
                let voiceBinding = Binding(get: {
                    model.talker.voice?.identifier ?? ""
                },
                                          set: { nv in
                    model.talker.voice = model.talker.voices.first(where: { $0.identifier == nv })
                    dummy.toggle()
                })
                Picker(selection: voiceBinding) {
                    ForEach(model.talker.voices) {
                        Text("\($0.name)").tag($0.identifier)
                        let _ = dummy
                    }
                } label: {
                    Text("using voice: \(model.talker.voice?.name ?? "unspecified")")
                }
            } label: {
                Text("Voice:")
            }.pickerStyle(.menu)

            Spacer()

            let degreeBinding = Binding(get: {
                model.tracker.offAxisAngle.degrees
            }, set: {
                model.tracker.offAxisAngle = Angle2D(degrees: $0)
            })
            VStack {
                Slider(value: degreeBinding,
                       in: -45 ... 45,
                       step: 1,
                       label: { EmptyView() },
                       minimumValueLabel: { Text("-45º") },
                       maximumValueLabel: { Text("45º") })
                Text("off-axis angle: \(model.tracker.offAxisAngle.degrees, format: .number.rounded())º")
            }
            .accessibilityRepresentation {
                Slider(value: degreeBinding,
                       in: -45 ... 45,
                       step: 1,
                       label: { Text("off-axis angle") })
                .accessibilityValue("\(model.tracker.offAxisAngle.degrees, format: .number.rounded())º")
            }

            Spacer()
            Button("Zero pitch and roll") {
                model.tracker.zero()
            }
            .buttonStyle(.bordered)

            Spacer()
            Spacer()
        }
        .padding()
    }
}
