//
//  PositionTracker.swift
//  EarPilot
//
//  Created by Rogers George on 1/19/24.
//

import Foundation
import CoreMotion

@Observable class PositionTracker {
    let manager = CMMotionManager()

    var attitude: CMAttitude?
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
        if let zeroReference {
            let att = motion.attitude
            att.multiply(byInverseOf: zeroReference)
            attitude = att
        } else {
            attitude = motion.attitude
            zeroReference = motion.attitude
        }
    }

    func zero() {
        zeroReference = manager.deviceMotion?.attitude
    }
}
