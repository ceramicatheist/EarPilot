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
                .padding(.horizontal, -15)

            Spacer()

            Toggle(isOn: model.$shouldSpeakBank, label: {
                Text("Speak Bank Angles")
            })

//            Toggle(isOn: model.$shouldSoundCoordination) {
//                Text("Change voice for slip/skid")
//            }

            Toggle(isOn: model.$shouldBeepPitch, label: {
                Text("Beep Pitch Angle")
            })

            Toggle(isOn: model.$shouldSpeakCompass, label: {
                Text("Speak Compass Points")
            })

            Spacer()

            Button("Zero pitch and roll") {
                model.tracker.zero()
            }
            .buttonStyle(.bordered)

            Spacer()

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

            LabeledContent {
                let degreeBinding = Binding(get: {
                    model.tracker.offAxisAngle.degrees
                }, set: {
                    model.tracker.offAxisAngle = Angle2D(degrees: $0)
                })

                Picker(selection: degreeBinding) {
                    ForEach(Array(stride(from: -30.0, to: 30.0, by: 5.0)), id: \.self) {
                        Text("\(abs($0).formatted(.number.rounded()))º \($0 < 0 ? "left" : $0 > 0 ? "right" : "")").tag($0)
                        let _ = dummy
                    }
                } label: {
                    Text("Off-Axis Mount Angle:")
                }

            } label: {
                Text("Off-Axis Mount Angle:")
            }.pickerStyle(.menu)
        }
        .padding(15)
    }
}
