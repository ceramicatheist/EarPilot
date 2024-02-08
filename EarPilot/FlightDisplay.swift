//
//  FlightDisplay.swift
//  EarPilot
//
//  Created by Rogers George on 1/19/24.
//

import SwiftUI
import CoreMotion

struct FlightDisplay: View {

    @StateObject var tracker = PositionTracker()
    @State var talker = Talker()

    var body: some View {
        VStack {
            ArtificialHorizon(tracker: tracker)
                .aspectRatio(1, contentMode: .fit)

            HStack {
                Spacer()
                Button("Zero pitch+roll") {
                    tracker.zero()
                }
                Spacer()
                Button("Zero heading") {
                    tracker.zeroHeading()
                }
                Spacer()
                Button("Say something") {
                    talker.speak((Int.random(in: 0...18) * 5).description)
                }
            }
            .buttonStyle(.bordered)
        }
    }
}
