//
//  EarPilotApp.swift
//  EarPilot
//
//  Created by Rogers George on 1/19/24.
//

import SwiftUI
import UIKit

@main
struct EarPilotApp: App {
    var body: some Scene {
        WindowGroup {
            FlightDisplay()
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = true
                }
        }
    }
}
