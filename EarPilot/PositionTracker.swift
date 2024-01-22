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

    var attitude: Rotation3D = Rotation3D.identity
    var zeroReference: CMAttitude?

    var error: Error?

    init() {
        manager.deviceMotionUpdateInterval = 1 / 60
        manager.startDeviceMotionUpdates(to: OperationQueue.main,
                                         withHandler: self.motionHandler)
    }

    func motionHandler(_ motion: CMDeviceMotion?, _ err: Error?) {
        if let err { self.error = err }
        guard let motion else {return}
        if zeroReference == nil {
            zeroReference = motion.attitude
        }
        if let zeroReference {
            let att = motion.attitude
            att.multiply(byInverseOf: zeroReference)
            attitude = Rotation3D(simd_quatd(ix: att.quaternion.x,
                                             iy: att.quaternion.y,
                                             iz: att.quaternion.z,
                                             r: att.quaternion.w))
        }
    }

    func zero() {
        zeroReference = manager.deviceMotion?.attitude
    }
}
