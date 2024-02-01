//
//  FlightDisplay.swift
//  EarPilot
//
//  Created by Rogers George on 1/19/24.
//

import SwiftUI
import CoreMotion

struct FlightDisplay: View {

    @State var tracker = PositionTracker()

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
            }
            .buttonStyle(.bordered)
        }
    }
}
