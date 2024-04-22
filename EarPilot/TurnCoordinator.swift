//
//  TurnCoordinator.swift
//  EarPilot
//
//  Created by Rogers George on 4/22/24.
//

import SwiftUI

@MainActor
struct TurnCoordinator: View {
    var coordination: Double // negative is left

    var body: some View {

        GeometryReader { g in
            let box = g.frame(in: .local)
            Capsule(style: .circular).stroke()
            Rectangle().stroke().aspectRatio(1, contentMode: .fit).position(x: box.midX, y: box.midY)
            Circle().position(x: box.midX + g.size.width * coordination.clamped(to: -0.5...0.5),
                              y: box.midY)
        }
        .frame(maxHeight: 32)
    }
}

extension BinaryFloatingPoint {
    func clamped(to range: ClosedRange<Self>) -> Self {
        (self...self).clamped(to: range).lowerBound
    }
}
