//
//  ModelController.swift
//  EarPilot
//
//  Created by Rogers George on 2/11/24.
//

import Foundation
import Combine
import Spatial
import SwiftUI

class ModelController: ObservableObject {

    @AppStorage("bankEnabled") var shouldSpeakBank = true
    @AppStorage("pitchEnabled") var shouldBeepPitch = true
    @AppStorage("headingEnabled") var shouldSpeakCompass = true
    //@AppStorage("coordinationEnabled") var shouldSoundCoordination = true
    let shouldSoundCoordination = true

    let tracker = PositionTracker()
    let talker = Talker()

    private var subscriptions = [AnyCancellable]()

    init() {
        tracker.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }.store(in: &subscriptions)
        tracker.$roll.sink { [weak self] roll in
            self?.updateRoll(roll, self?.tracker.coordination ?? 0)
        }.store(in: &subscriptions)
        tracker.$pitch.sink { [weak self] pitch in
            self?.updatePitch(pitch)
        }.store(in: &subscriptions)
        tracker.$heading.sink { [weak self] heading in
            self?.updateHeading(heading)
        }.store(in: &subscriptions)
    }

    private var lastRoll: (Int, Double, Date) = (0, 0, .distantPast)
    private var lastLeveling = true // true when rolling toward level
    let idleInterval = TimeInterval(2)

    private func updateRoll(_ roll: Angle2D, _ coordination: Double) {
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
        guard shouldSpeakBank else {return}
        let adjust = shouldSoundCoordination ? coordination : 0
        switch number {
        case 0:
            talker.speak("Level,", .zero)

        case ...0 :
            talker.speak("\(abs(number))\(punc)", Angle2D(degrees: -90), pitchShift: adjust)

        default:
            talker.speak("\(number)\(punc)", Angle2D(degrees: 90), pitchShift: -adjust)
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
        guard shouldBeepPitch else {return}
        talker.beep(number)
    }

    private var lastHeading: (Angle2D, Date) = (.zero, .distantPast)
    private func updateHeading(_ heading: Angle2D) {
        let now = Date()
        let delta = abs(lastHeading.0.circularDifference(from: heading).degrees)

        if delta < 2
            || (delta < 5 && now.timeIntervalSince(lastHeading.1) < idleInterval)
            || (delta < 10 && now.timeIntervalSince(lastHeading.1) < 1)
        { return }

        lastHeading = (heading, now)

        guard shouldSpeakCompass else {return}
        let compass: String
        let angle: Angle2D
        switch heading.degrees {
        case 0..<45:
            compass = "north"
            angle = heading
        case 45..<135:
            compass = "east"
            angle = heading - .degrees(90)
        case 135..<225:
            compass = "south"
            angle = heading - .degrees(180)
        case 225..<315:
            compass = "west"
            angle = heading - .degrees(270)
        case 315...360:
            compass = "north"
            angle = heading - .degrees(360)
        default:
            compass = "error"
            angle = .zero
        }
        talker.speak(compass, .degrees(-angle.degrees * 1.25 /* fudge the separation a bit wider */), useOtherVoice: true)
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

extension Angle2D {
    func circularDifference(from: Angle2D) -> Angle2D {
        Angle2D.atan2(y: sin( self - from ),
                      x: cos( self - from ))
    }
}
