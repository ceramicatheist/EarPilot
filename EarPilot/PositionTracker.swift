//
//  PositionTracker.swift
//  EarPilot
//
//  Created by Rogers George on 1/19/24.
//

import Foundation
import CoreMotion
import SwiftUI
import Spatial

class PositionTracker: ObservableObject {
    
    @Published private(set) var pitch = Angle2D.zero

    @Published private(set) var roll = Angle2D.zero

    @Published private(set) var yaw = Angle2D.zero // arbitrary zero

    @Published private(set) var heading = Angle2D.zero // positive, 0=north

    @Published private(set) var coordination = Double(0)

    @Published private(set) var rateOfClimb = Double(0) // feet/min

    var offAxisAngle: Angle2D {
        get {
            .degrees(offAxisAngleDegrees)
        }
        set {
            offAxisAngleDegrees = newValue.degrees
            (attitude, _) = (attitude, ())
        }
    }

    @AppStorage("offAxisAngle") private var offAxisAngleDegrees: Double = 0

    private let manager = CMMotionManager()
    private let header = CMMotionManager()
    private let altimeter = CMAltimeter()

    private var attitude: Rotation3D = .identity {
        didSet {
            guard let zeroAttitude else {
                pitch = .zero
                roll = .zero
                yaw = .zero
                return
            }

            let yawRelativeAttitude = attitude * zeroAttitude.inverse
            let relativeYaw = yawRelativeAttitude.twistAngle(around: .z)

            let twistedZero = zeroAttitude.rotated(by: Rotation3D(angle: relativeYaw, axis: .z))
            let relativeAttitude = attitude * twistedZero.inverse

            let absoluteYaw = attitude.twist(twistAxis: .z).rotated(by: Rotation3D(angle: -offAxisAngle, axis: .z))
            roll = relativeAttitude.twistAngle(around: .y.rotated(by: absoluteYaw))
            pitch = relativeAttitude.twistAngle(around: .x.rotated(by: absoluteYaw))
            yaw = (.degrees(270) - absoluteYaw.twistAngle(around: .z)).normalized
        }
    }

    private var zeroAttitude: Rotation3D?
    private var zeroAccel: CMAccelerometerData?

    private var alts: [CMAltitudeData] = []

    init() {
        manager.deviceMotionUpdateInterval = 1 / 30
        manager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical,
                                         to: .main,
                                         withHandler: motionHandler)
        header.deviceMotionUpdateInterval = 1 / 4
        header.startDeviceMotionUpdates(using: .xMagneticNorthZVertical,
                                        to: .main,
                                        withHandler: headingHandler)
        manager.accelerometerUpdateInterval = 1 / 30
        manager.startAccelerometerUpdates(to: .main,
                                          withHandler: accelHandler)
        altimeter.startRelativeAltitudeUpdates(to: .main, withHandler: altitudeHandler)
    }

    func motionHandler(_ motion: CMDeviceMotion?, _ err: Error?) {
        guard let motion else {
            zeroAttitude = nil
            attitude = .identity
            return
        }
        let att = Rotation3D(motion.attitude.quaternion)
        if zeroAttitude == nil { zeroAttitude = att }
        self.attitude = att
    }

    func headingHandler(_ motion: CMDeviceMotion?, _ err: Error?) {
        guard let motion else {
            heading = .zero
            return
        }
        var deg = motion.heading - offAxisAngleDegrees
        if deg < 0 { deg += 360 }
        if deg > 360 { deg -= 360 }
        heading = .init(degrees: deg)
    }

    func accelHandler(_ accel: CMAccelerometerData?, _ err: Error?) {
        guard let accel else {
            zeroAccel = nil
            coordination = 0
            return
        }
        if zeroAccel == nil { zeroAccel = accel }
        guard let zeroAccel else { return /* tsnh */ }

        let x = accel.acceleration.x - zeroAccel.acceleration.x

        let beta = Double(0.1)
        coordination = (x * beta) + (coordination * (1 - beta))
    }

    func altitudeHandler(_ alt: CMAltitudeData?, _ err: Error?) {
        guard let alt else {
            rateOfClimb = 0
            return
        }
        alts.append(alt)
        alts = alts.suffix(3)
        let metersPerSec: Double
        switch alts.count {
        case 3:
            let c1 = alts[0].relativeAltitude.doubleValue
            let c2 = alts[1].relativeAltitude.doubleValue * -4
            let c3 = alts[2].relativeAltitude.doubleValue * 3
            let deltaT = alts[2].timestamp - alts[0].timestamp // assume alts[1] is about in the middle
            metersPerSec = deltaT > 0 ? (c1 + c2 + c3) / deltaT : 0
        case 2:
            let deltaY = alts[1].relativeAltitude.doubleValue - alts[0].relativeAltitude.doubleValue
            let deltaT = alts[1].timestamp - alts[0].timestamp
            metersPerSec = deltaT > 0 ? deltaY / deltaT : 0
        default:
            metersPerSec = 0
        }
        let metersPerMinute = metersPerSec * 60
        let fpm = Measurement(value: metersPerMinute, unit: UnitLength.meters).converted(to: UnitLength.feet).value
        let beta = Double(0.5)
        rateOfClimb = (fpm * beta) + (rateOfClimb * (1 - beta))
    }

    func zero() {
        zeroAttitude = nil
        coordination = 0
    }
}
