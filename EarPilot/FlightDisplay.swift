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
    @AppStorage("bankStep") private var bankStep: Int = 5
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            InstrumentationView(tracker: model.tracker)
                .aspectRatio(1, contentMode: .fill)
            VStack(spacing: 2) {
                Toggle(isOn: $shouldSpeakBank, label: {
                    HStack {
                        Text("Speak Bank Angles")
                        Spacer()
                        Picker(selection: $bankStep) {
                            ForEach(1...5, id: \.self) { deg in
                                Text("every \(deg)º").tag(deg)
                            }
                        } label: {
                            Text("Speak Bank Angles")
                        }
                    }
                })

                Toggle(isOn: $shouldBeepPitch, label: {
                    Text("Beep Pitch Angle")
                })

                Toggle(isOn: $shouldSpeakCompass, label: {
                    Text("Speak Compass Points")
                })

                Spacer(minLength: 0)

                ViewThatFits {
                    Button {
                        model.tracker.zero()
                    } label: {
                        Text("Zero pitch and roll").padding()
                    }

                    Button {
                        model.tracker.zero()
                    } label: {
                        Text("Zero pitch and roll")
                    }
                }
                .buttonStyle(.bordered)

                Spacer(minLength: 0)

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
                        ForEach(Array(stride(from: -20.0, to: 20.0, by: 2.0)), id: \.self) {
                            Text("\(abs($0).formatted(.number.rounded()))º \($0 < 0 ? "left" : $0 > 0 ? "right" : "")").tag($0)
                        }
                    } label: {
                        Text("Off-Axis Mount Angle:")
                    }
                } label: {
                    Text("Off-Axis Mount Angle:")
                }

                LabeledContent {
                    @Bindable var tracker = model.tracker

                    Picker(selection: $tracker.useGpsHeading) {
                        Text("GPS").tag(true)
                        Text("Compass").tag(false)
                    } label: {
                        Text("Compass Source:")
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                } label: {
                    Text("Compass Source:")
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
