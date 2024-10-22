//
//  Spatial+extra.swift
//  EarPilot
//
//  Created by Rogers George on 2/12/24.
//

import Foundation
import Spatial
import CoreMotion

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

extension RotationAxis3D: @retroactive Rotatable3D {

    public func rotated(by rotation: Rotation3D) -> RotationAxis3D {
        Self(rotation * Vector3D(vector: self.vector))
    }

    public func rotated(by quaternion: simd_quatd) -> RotationAxis3D {
        rotated(by: Rotation3D(quaternion))
    }
}
