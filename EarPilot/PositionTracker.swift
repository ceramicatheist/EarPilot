//
//  PositionTracker.swift
//  EarPilot
//
//  Created by Rogers George on 1/19/24.
//

import Foundation
import CoreMotion
import Spatial

class PositionTracker: ObservableObject {
    
    @Published var pitch = Angle2D.zero

    @Published var roll = Angle2D.zero

    @Published var yaw = Angle2D.zero

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
            yaw = yawRelativeAttitude.twistAngle(around: RotationAxis3D.z)

            let twistedZero = zeroAttitude.rotated(by: Rotation3D(angle: yaw, axis: RotationAxis3D.z))
            let relativeAttitude = attitude * twistedZero.inverse

            let absoluteYaw = attitude.twist(twistAxis: RotationAxis3D.z)
            let forward = RotationAxis3D.y.rotated(by: absoluteYaw)
            let rightward = RotationAxis3D.x.rotated(by: absoluteYaw)

            roll = relativeAttitude.twistAngle(around: forward)

            pitch = relativeAttitude.twistAngle(around: rightward)
        }
    }

    private var zeroAttitude: Rotation3D?

    init() {
        manager.deviceMotionUpdateInterval = 1 / 60
        manager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical,
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
    }

    func zero() {
        zeroAttitude = nil
    }
}
