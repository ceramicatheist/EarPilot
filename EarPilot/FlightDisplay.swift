//
//  FlightDisplay.swift
//  EarPilot
//
//  Created by Rogers George on 1/19/24.
//

import SwiftUI
import CoreMotion

struct FlightDisplay: View {

    @StateObject var model = ModelController()

    var body: some View {
        VStack {
            ArtificialHorizon(tracker: model.tracker)
                .aspectRatio(1, contentMode: .fit)

            HStack {
                Spacer()
                Button("Zero pitch+roll") {
                    model.tracker.zero()
                }
                Spacer()
                Button("Zero heading") {
                    model.tracker.zeroHeading()
                }
                Spacer()
                Button("Say something") {
                    model.talker.speak((Int.random(in: 0...18) * 5).description)
                }
                Spacer()
                Button("Beep") {
                    model.talker.beep()
                }
                Spacer()
            }
            .buttonStyle(.bordered)
        }
    }
}
