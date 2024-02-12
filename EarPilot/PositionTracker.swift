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
            guard let rightward, let forward, let zeroAttitude else {
                pitch = .zero
                roll = .zero
                yaw = .zero
                return
            }
            let attitude = attitude * zeroAttitude.inverse
            pitch = attitude.twistAngle(around: rightward)
            roll = attitude.twistAngle(around: forward)
            yaw = attitude.twistAngle(around: RotationAxis3D.z)
        }
    }

    private var zeroAttitude: Rotation3D?
    private var forward: RotationAxis3D?
    private var rightward: RotationAxis3D?

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
        if forward == nil {
            let twist = att.twist(twistAxis: RotationAxis3D.z)
            forward = RotationAxis3D.y.rotated(by: twist)
            rightward = RotationAxis3D.x.rotated(by: twist)
        }
        self.attitude = att
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
