//
//  PositionTracker.swift
//  EarPilot
//
//  Created by Rogers George on 1/19/24.
//

import Foundation
import CoreMotion
import CoreLocation
import SwiftUI
import Spatial

@MainActor @Observable class PositionTracker: NSObject {

    private(set) var pitch = Angle2D.zero

    private(set) var roll = Angle2D.zero

    private(set) var yaw = Angle2D.zero // arbitrary zero

    private(set) var magHeading = Angle2D.zero // positive, 0=north

    private(set) var gpsHeading = Angle2D.zero

    var heading: Angle2D { useGpsHeading ? gpsHeading : magHeading }

    private(set) var coordination = Double(0)

    private(set) var rateOfClimb = Double(0) // feet/min

    var altitude = Double(0) // feet

    var offAxisAngle: Angle2D {
        get {
            _$observationRegistrar.access(self, keyPath: \.offAxisAngle)
            return .degrees(offAxisAngleDegrees)
        }
        set {
            _$observationRegistrar.withMutation(of: self, keyPath: \.offAxisAngle) {
                offAxisAngleDegrees = newValue.degrees
                (attitude, _) = (attitude, ())
            }
        }
    }

    var useGpsHeading = false

    @ObservationIgnored @AppStorage("offAxisAngle") private var offAxisAngleDegrees: Double = 0

    private let manager = CMMotionManager()
    private let gps = CLLocationManager()
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

            let relativeYaw = (attitude * zeroAttitude.inverse).twistAngle(around: .z)

            let attitudeMinusYaw = attitude.rotated(by: Rotation3D(angle: -relativeYaw, axis: .z))

            let relativeAttitude = attitudeMinusYaw * zeroAttitude.inverse

            let absoluteYaw = Rotation3D(angle: zeroAttitude.twistAngle(around: .z),
                                         axis: .z)
            let forward = RotationAxis3D.y.rotated(by: absoluteYaw)
            let right = RotationAxis3D.x.rotated(by: absoluteYaw)

            roll = relativeAttitude.twistAngle(around: forward)
            pitch = relativeAttitude.twistAngle(around: right)
            yaw = (.degrees(270) - relativeYaw).normalized
        }
    }

    private var zeroAttitude: Rotation3D?
    private var zeroAccel: CMAccelerometerData?

    private var alts: [CMAbsoluteAltitudeData] = []

    override init() {
        super.init()
        gps.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        gps.requestAlwaysAuthorization()
        gps.delegate = self
        gps.startUpdatingLocation()
        gps.startUpdatingHeading()

        manager.deviceMotionUpdateInterval = 1 / 30
        manager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical,
                                         to: .main,
                                         withHandler: motionHandler)
        header.deviceMotionUpdateInterval = 1 / 10
        header.startDeviceMotionUpdates(using: .xMagneticNorthZVertical,
                                        to: .main,
                                        withHandler: headingHandler)
        manager.accelerometerUpdateInterval = 1 / 30
        manager.startAccelerometerUpdates(to: .main,
                                          withHandler: accelHandler)
        altimeter.startAbsoluteAltitudeUpdates(to: .main, withHandler: altitudeHandler)
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
            magHeading = .zero
            return
        }
        var deg = motion.heading - offAxisAngleDegrees
        if deg < 0 { deg += 360 }
        if deg > 360 { deg -= 360 }
        magHeading = .init(degrees: deg)
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

        let beta = Double(0.05)
        coordination = (x * beta) + (coordination * (1 - beta))
    }

    func altitudeHandler(_ alt: CMAbsoluteAltitudeData?, _ err: Error?) {
        guard let alt else {
            rateOfClimb = 0
            return
        }
        alts.append(alt)
        alts = alts.suffix(3)
        let metersPerSec: Double
        switch alts.count {
        case 3:
            let c1 = alts[0].altitude
            let c2 = alts[1].altitude * -4
            let c3 = alts[2].altitude * 3
            let deltaT = alts[2].timestamp - alts[0].timestamp // assume alts[1] is about in the middle
            metersPerSec = deltaT > 0 ? (c1 + c2 + c3) / deltaT : 0
        case 2:
            let deltaY = alts[1].altitude - alts[0].altitude
            let deltaT = alts[1].timestamp - alts[0].timestamp
            metersPerSec = deltaT > 0 ? deltaY / deltaT : 0
        default:
            metersPerSec = 0
        }
        let metersPerMinute = metersPerSec * 60
        let fpm = Measurement(value: metersPerMinute, unit: UnitLength.meters).converted(to: UnitLength.feet).value
        let beta = Double(0.1)
        rateOfClimb = (fpm * beta) + (rateOfClimb * (1 - beta))

        let meters = alts.map(\.altitude).reduce(0.0, +) / Double(alts.count)
        self.altitude = Measurement(value: meters, unit: UnitLength.meters).converted(to: .feet).value
    }

    func zero() {
        zeroAttitude = nil
        zeroAccel = nil
        coordination = 0
    }
}

extension Angle2D {
    var mutableDegrees: Double {
        get {
            self.degrees
        }
        set {
            self = .degrees(newValue)
        }
    }
}

extension PositionTracker: @MainActor CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("loc \(locations.last, default: "?")")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.magneticHeading >= 0 {
            gpsHeading = Angle2D(degrees: newHeading.magneticHeading)
        }
    }
}
