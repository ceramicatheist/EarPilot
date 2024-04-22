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

    @Published private(set) var yaw = Angle2D.zero

    @Published private(set) var coordination = Double(0)

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

            var yaw = (.degrees(270) - absoluteYaw.twistAngle(around: .z)).normalized
            if yaw.degrees < 0 { yaw += .degrees(360) }
            self.yaw = yaw
        }
    }

    private var zeroAttitude: Rotation3D?

    init() {
        manager.deviceMotionUpdateInterval = 1 / 60
        manager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical,
                                         to: OperationQueue.main,
                                         withHandler: motionHandler)
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
        let coord = Vector3D(x: motion.gravity.x + motion.userAcceleration.x,
                             y: motion.gravity.y + motion.userAcceleration.y,
                             z: motion.gravity.z + motion.userAcceleration.z).rotated(by: zeroAttitude!).y
        let beta = Double(0.1)
        coordination = (coord * beta) + (coordination * (1 - beta))
    }

    func zero() {
        zeroAttitude = nil
        coordination = 0
    }
}
