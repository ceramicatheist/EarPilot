//
//  ModelController.swift
//  EarPilot
//
//  Created by Rogers George on 2/11/24.
//

import Foundation
import Combine
import Spatial

class ModelController: ObservableObject {

    let tracker = PositionTracker()
    let talker = Talker()

    private lazy var sub1 = tracker.objectWillChange.sink { [weak self] in
        self?.objectWillChange.send()
    }

    private lazy var sub2 = tracker.$roll.sink { [weak self] roll in
        self?.updateRoll(roll)
    }

    init() {
        _ = sub1
        _ = sub2
    }

    private var lastRoll: (Int, Double, Date) = (0, 0, .distantPast)
    let idleInterval = TimeInterval(2)

    private func updateRoll(_ roll: Angle2D) {
        let degrees = roll.degrees
        let number = Int(degrees.rounded(toMultipleOf: 5))
        if number == 0 && lastRoll.0 == 0 {return}
        let now = Date()
        if number == lastRoll.0 && now.timeIntervalSince(lastRoll.2) < idleInterval {return}

        // rising or falling pitch depends on sign of roll velocity
        let punc = abs(degrees) < abs(lastRoll.1) ? "?" : "."

        lastRoll = (number, degrees, now)
        switch number {
        case 0:
            talker.speak("Level.", .center)

        case ...0 :
            talker.speak("\(abs(number))\(punc)", .left)

        default:
            talker.speak("\(number)\(punc)", .right)
        }
    }
}

extension FloatingPoint
{
    func rounded(toMultipleOf x: Self,
                 rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero)
    -> Self
    {
        return (self / x).rounded(rule) * x
    }

    mutating func round(toMultipleOf x: Self,
                        rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero)
    {
        self = self.rounded(toMultipleOf: x, rule: rule)
    }
}
