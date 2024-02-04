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
    let manager = CMMotionManager()

    @Published var attitude: Rotation3D = .identity
    @Published var zeroAttitude: Rotation3D?

    var forward: RotationAxis3D?
    var rightward: RotationAxis3D?

    var pitch: Angle2D {
        guard let rightward, let zeroAttitude else {return .zero}
        let attitude = self.attitude * zeroAttitude.inverse
        return attitude.twistAngle(around: rightward)
    }

    var roll: Angle2D {
        guard let forward, let zeroAttitude else {return .zero}
        let attitude = self.attitude * zeroAttitude.inverse
        return attitude.twistAngle(around: forward)
    }

    var yaw: Angle2D {
        guard let zeroAttitude else {return .zero}
        let attitude = self.attitude * zeroAttitude.inverse
        return attitude.twistAngle(around: RotationAxis3D.z)
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
        if zeroAttitude == nil { zeroAttitude = attitude}
        if forward == nil {
            let twist = attitude.twist(twistAxis: RotationAxis3D.z)
            forward = RotationAxis3D.y.rotated(by: twist)
            rightward = RotationAxis3D.x.rotated(by: twist)
        }
    }

    func zero() {
        zeroAttitude = nil
    }

    func zeroHeading() {
        forward = nil
        rightward = nil
        zeroAttitude = nil
    }
}

extension Rotation3D {
    init(_ quat: CMQuaternion) {
        self.init(simd_quatf(ix: Float(quat.x),
                             iy: Float(quat.y),
                             iz: Float(quat.z),
                             r: Float(quat.w)))
    }

    init(_ quat: simd_quatd) {
        self.init(simd_quatf(ix: Float(quat.imag.x),
                             iy: Float(quat.imag.y),
                             iz: Float(quat.imag.z),
                             r: Float(quat.real)))
    }

    // get negative twist angles too
    func twistAngle(around axis: RotationAxis3D) -> Angle2D {
        let twist = self.twist(twistAxis: axis)
        if dot(twist.axis.vector, axis.vector).sign == .minus {
            return -twist.angle
        } else {
            return twist.angle
        }
    }
}

extension RotationAxis3D: Rotatable3D {

    public func rotated(by rotation: Rotation3D) -> RotationAxis3D {
        Self(rotation * Vector3D(vector: self.vector))
    }
    
    public func rotated(by quaternion: simd_quatd) -> RotationAxis3D {
        rotated(by: Rotation3D(quaternion))
    }
}
