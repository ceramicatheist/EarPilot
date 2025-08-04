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

    @State var model: ModelController

    @AppStorage("bankEnabled") var shouldSpeakBank = true
    @AppStorage("pitchEnabled") var shouldBeepPitch = true
    @AppStorage("headingEnabled") var shouldSpeakCompass = true

    var body: some View {
        VStack(spacing: 0) {
            InstrumentationView(tracker: model.tracker)
                .containerRelativeFrame(.vertical, count: 2, spacing: 0)
            VStack {
                Toggle(isOn: model.$shouldSpeakBank, label: {
                    Text("Speak Bank Angles")
                })

                Toggle(isOn: model.$shouldBeepPitch, label: {
                    Text("Beep Pitch Angle")
                })

                Toggle(isOn: model.$shouldSpeakCompass, label: {
                    Text("Speak Compass Points")
                })

                Spacer(minLength: -10)

                Button("Zero pitch and roll") {
                    model.tracker.zero()
                }
                .buttonStyle(.bordered)

                Spacer(minLength: -10)

                LabeledContent {
                    @Bindable var talker = model.talker

                    Picker(selection: $talker.voice) {
                        ForEach(model.talker.voices) {
                            Text("\($0.name)").tag($0)
                        }
                    } label: {
                        Text("using voice \(model.talker.voice?.name ?? "unspecified") for bank")
                    }
                } label: {
                    Text("Bank Voice:")
                }

                LabeledContent {
                    @Bindable var talker = model.talker

                    Picker(selection: $talker.otherVoice) {
                        ForEach(model.talker.voices) {
                            Text("\($0.name)").tag($0)
                        }
                    } label: {
                        Text("using voice \(model.talker.otherVoice?.name ?? "unspecified") for heading")
                    }
                } label: {
                    Text("Heading Voice:")
                }

                LabeledContent {
                    @Bindable var tracker = model.tracker

                    Picker(selection: $tracker.offAxisAngle.mutableDegrees) {
                        ForEach(Array(stride(from: -30.0, to: 30.0, by: 5.0)), id: \.self) {
                            Text("\(abs($0).formatted(.number.rounded()))º \($0 < 0 ? "left" : $0 > 0 ? "right" : "")").tag($0)
                        }
                    } label: {
                        Text("Off-Axis Mount Angle:")
                    }

                } label: {
                    Text("Off-Axis Mount Angle:")
                }
            }
            .padding([.top, .horizontal])
            .pickerStyle(.menu)
        }
    }
}
