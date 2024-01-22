//
//  ArtificialHorizon.swift
//  EarPilot
//
//  Created by Rogers George on 1/20/24.
//

import SwiftUI
import SceneKit
import Spatial

struct ArtificialHorizon: View {

    private(set) var tracker: PositionTracker

    @State private var scene: SCNScene
    var rootNode: SCNNode
    var zero: SCNMatrix4

    init(tracker: PositionTracker) {
        self.tracker = tracker
        let scene = SCNScene(named: "art.scnassets/Character/max.scn")!
        let rootNode = scene.rootNode.childNode(withName: "Max_rootNode", recursively: true)!
        self.scene = scene
        self.rootNode = rootNode
        zero = rootNode.transform
    }

    var body: some View {
        SceneView(scene: scene,
                  options: [.autoenablesDefaultLighting, .rendersContinuously],
                  antialiasingMode: .none)
        .onChange(of: tracker.attitude) { oldValue, newValue in
            rootNode.transform = zero
            rootNode.rotate(by: SCNQuaternion(newValue.inverse),
                            aroundTarget: SCNVector3(0, 0, 0))
        }
    }
}

extension SCNQuaternion {
    init(_ rot: Rotation3D) {
        let quat = rot.quaternion
        self = SCNQuaternion(x: Float(quat.imag.x),
                             y: Float(quat.imag.y),
                             z: Float(quat.imag.z),
                             w: Float(quat.real))
    }
}
