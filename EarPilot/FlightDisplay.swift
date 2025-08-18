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
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            InstrumentationView(tracker: model.tracker)
                .aspectRatio(1, contentMode: .fill)
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

                Button {
                    model.tracker.zero()
                } label: {
                    Text("Zero pitch and roll").padding()
                }
                .buttonStyle(.bordered)

                Spacer(minLength: -10)

                if let talker = model.talker {
                    @Bindable var talker = talker
                    LabeledContent {

                        Picker(selection: $talker.voice) {
                            ForEach(talker.voices) {
                                Text("\($0.name)").tag($0)
                            }
                        } label: {
                            Text("using voice \(talker.voice?.name ?? "unspecified") for bank")
                        }
                    } label: {
                        Text("Bank Voice:")
                    }

                    LabeledContent {
                        Picker(selection: $talker.otherVoice) {
                            ForEach(talker.voices) {
                                Text("\($0.name)").tag($0)
                            }
                        } label: {
                            Text("using voice \(talker.otherVoice?.name ?? "unspecified") for heading")
                        }
                    } label: {
                        Text("Heading Voice:")
                    }
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
        .onChange(of: scenePhase, initial: true) { _, newValue in
            model.makeNoise = (newValue == .active)
        }
    }
}
