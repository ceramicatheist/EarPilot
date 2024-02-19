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

    private var subscriptions = [AnyCancellable]()

    init() {
        tracker.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }.store(in: &subscriptions)
        tracker.$roll.sink { [weak self] roll in
            self?.updateRoll(roll)
        }.store(in: &subscriptions)
        tracker.$pitch.sink { [weak self] pitch in
            self?.updatePitch(pitch)
        }.store(in: &subscriptions)
    }

    private var lastRoll: (Int, Double, Date) = (0, 0, .distantPast)
    private var lastLeveling = true // true when rolling toward level
    let idleInterval = TimeInterval(2)

    private func updateRoll(_ roll: Angle2D) {
        let degrees = roll.degrees
        let number = Int(degrees.rounded(toMultipleOf: 5))
        if number == 0 && lastRoll.0 == 0 {return}
        let now = Date()
        let leveling = abs(degrees) < abs(lastRoll.1)
        if number == lastRoll.0 && leveling == lastLeveling && now.timeIntervalSince(lastRoll.2) < idleInterval {return}

        // rising or falling pitch depends on sign of roll velocity
        let punc = leveling ? "?" : "."

        lastRoll = (number, degrees, now)
        lastLeveling = leveling
        switch number {
        case 0:
            talker.speak("Level.", .center)

        case ...0 :
            talker.speak("\(abs(number))\(punc)", .left)

        default:
            talker.speak("\(number)\(punc)", .right)
        }
    }

    private var lastPitch: (Int, Date) = (0, .distantPast)

    private func updatePitch(_ pitch: Angle2D) {

        let degrees = pitch.degrees / 3
        let number = Int(degrees.rounded())
        if number == 0 && lastPitch.0 == 0 {return}
        let now = Date()
        if number == lastPitch.0 && now.timeIntervalSince(lastPitch.1) < idleInterval {return}

        lastPitch = (number, now)
        talker.beep(number)
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
