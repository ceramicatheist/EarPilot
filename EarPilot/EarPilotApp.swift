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

    let model = ModelController()
    
    var body: some Scene {
        WindowGroup {
            FlightDisplay(model: model)
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = true
                }
                .colorScheme(.dark)
                .preferredColorScheme(.dark)
                .tint(.yellow)
        }
    }
}
