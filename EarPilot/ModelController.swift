//
//  ModelController.swift
//  EarPilot
//
//  Created by Rogers George on 2/11/24.
//

import Foundation
import Observation
import Spatial
import SwiftUI

@MainActor @Observable class ModelController {

    @ObservationIgnored @AppStorage("bankEnabled") private var shouldSpeakBank = true
    @ObservationIgnored @AppStorage("pitchEnabled") private var shouldBeepPitch = true
    @ObservationIgnored @AppStorage("headingEnabled") private var shouldSpeakCompass = true
    //@AppStorage("coordinationEnabled") var shouldSoundCoordination = true
    @ObservationIgnored @AppStorage("bankStep") private var bankStep: Int = 5
    let shouldSoundCoordination = true

    let tracker = PositionTracker()
    var talker: Talker?

    private var phase: Int = 0
    @ObservationIgnored
    lazy private var idleTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
        MainActor.assumeIsolated { [weak self] in
            guard let self else {return}
            switch phase {
            case 0: updatePitch(tracker.pitch, idle: true)
            case 1: updateRoll(tracker.roll, tracker.coordination, idle: true)
            case 2: updateHeading(tracker.heading, idle: true)
            default: ()
            }
            phase = (phase + 1) % 3
        }
    }

    init() {
        watchTracking()
        defer { _ = idleTimer }
    }

    var makeNoise: Bool {
        get {
            talker != nil
        }
        set {
            if newValue, talker == nil {
                talker = Talker()
            } else {
                talker = nil
            }
        }
    }

    func watchTracking() -> () {
        withObservationTracking {
            updateRoll(tracker.roll, tracker.coordination)
            updatePitch(tracker.pitch)
            updateHeading(tracker.heading)
        } onChange: {
            DispatchQueue.main.async { [weak self] in
                self?.watchTracking()
            }
        }
    }

    private struct RollSample: Hashable {
        var roundDegrees: Int
        var bucket: Double
        var degrees: Double
    }
    private var last: RollSample?

    private func updateRoll(_ roll: Angle2D, _ coordination: Double, idle: Bool = false) {
        let bucketSize = Double(bankStep)
        let current = RollSample(
            roundDegrees: Int(roll.degrees.rounded(toMultipleOf: bucketSize)),
            bucket: (roll.degrees + bucketSize / 2).rounded(toMultipleOf: bucketSize),
            degrees: roll.degrees,
        )
        if last == nil { last = current }

        if !idle
            && (current.bucket == last!.bucket || (current.roundDegrees == 0 && last!.roundDegrees == 0))
        {
            return
        }
        idleTimer.fireDate = .now + idleTimer.timeInterval
        // rising or falling pitch depends on sign of roll velocity
        let leveling = abs(last!.bucket) > abs(current.bucket)
        self.last = current
        
        guard shouldSpeakBank else {return}

        let punc = leveling ? "?" : "."
        let adjust = shouldSoundCoordination ? coordination * 4 : 0
        switch current.roundDegrees {
        case 0:
            talker?.speak("Level.", .zero)

        case ...0 :
            talker?.speak("\(abs(current.roundDegrees))\(punc)", Angle2D(degrees: -90), pitchShift: adjust)

        default:
            talker?.speak("\(current.roundDegrees)\(punc)", Angle2D(degrees: 90), pitchShift: -adjust)
        }
    }

    private var lastPitch = 0
    private func updatePitch(_ pitch: Angle2D, idle: Bool = false) {
        let degrees = pitch.degrees / 3
        let number = Int(degrees.rounded())
        if number == lastPitch && !idle {return}
        idleTimer.fireDate = .now + idleTimer.timeInterval
        lastPitch = number
        guard shouldBeepPitch else {return}
        talker?.beep(number)
    }

    private var lastHeading: Angle2D?
    private func updateHeading(_ heading: Angle2D, idle: Bool = false) {
        guard let lastHeading else { lastHeading = heading ; return }
        let delta = abs(lastHeading.circularDifference(from: heading).degrees)
        if delta < 10 && !idle { return }
        idleTimer.fireDate = .now + idleTimer.timeInterval
        self.lastHeading = heading
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
        talker?.speak(compass, .degrees(-angle.degrees * 1.25 /* fudge the separation a bit wider */), useOtherVoice: true)
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
