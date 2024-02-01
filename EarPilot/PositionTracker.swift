//
//  PositionTracker.swift
//  EarPilot
//
//  Created by Rogers George on 1/19/24.
//

import Foundation
import CoreMotion
import Spatial

@Observable class PositionTracker {
    let manager = CMMotionManager()

    var attitude: Rotation3D = .identity
    var zeroAttitude: Rotation3D = .identity

    let forward = RotationAxis3D.y
    let rightward = RotationAxis3D.x

    var pitch: Angle2D {
        let attitude = self.attitude * zeroAttitude.inverse

        let twist = attitude.twist(twistAxis: rightward)
        let sign = dot(twist.axis.vector, rightward.vector).sign
        if sign == .minus {
            return -twist.angle
        } else {
            return twist.angle
        }
    }

    var roll: Angle2D {
        let attitude = self.attitude * zeroAttitude.inverse

        let twist = attitude.twist(twistAxis: forward)
        let sign = dot(twist.axis.vector, forward.vector).sign
        if sign == .minus {
            return -twist.angle
        } else {
            return twist.angle
        }
    }

    var yaw: Angle2D {
        let attitude = self.attitude * zeroAttitude.inverse

        let twist = attitude.twist(twistAxis: RotationAxis3D.z)
        let sign = dot(twist.axis.vector, RotationAxis3D.z.vector).sign
        if sign == .minus {
            return -twist.angle
        } else {
            return twist.angle
        }
    }

    var error: Error?

    init() {
        manager.deviceMotionUpdateInterval = 1 / 60
        manager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical,
                                         to: OperationQueue.main,
                                         withHandler: self.motionHandler)
    }

    func motionHandler(_ motion: CMDeviceMotion?, _ err: Error?) {
        if let err { self.error = err }
        guard let motion else {return}
        attitude = Rotation3D(motion.attitude.quaternion)
    }

    func zero() {
        zeroAttitude = attitude
    }

    func zeroHeading() {
        // reset north + east
    }
}

extension Rotation3D {
    init(_ quat: CMQuaternion) {
        self.init(simd_quatf(ix: Float(quat.x),
                             iy: Float(quat.y),
                             iz: Float(quat.z),
                             r: Float(quat.w)))
    }
}
