//
//  ArtificialHorizon.swift
//  EarPilot
//
//  Created by Rogers George on 1/20/24.
//

import SwiftUI
import SceneKit

struct ArtificialHorizon: View {

    private(set) var tracker: PositionTracker

    @State private var scene: SCNScene
    var rootNode: SCNNode
    var zero: SCNVector4

    init(tracker: PositionTracker) {
        self.tracker = tracker
        let scene = SCNScene(named: "art.scnassets/Character/max.scn")!
        let rootNode = scene.rootNode.childNode(withName: "Max_rootNode", recursively: true)!
        self.scene = scene
        self.rootNode = rootNode
        self.zero = rootNode.rotation
    }

    var body: some View {
        SceneView(scene: scene,
                  options: [.autoenablesDefaultLighting, .rendersContinuously],
                  antialiasingMode: .none)
        .onChange(of: tracker.attitude) { oldValue, newValue in
            guard let quat = newValue?.quaternion else {return}
            rootNode.rotation = zero
            rootNode.rotate(by: SCNQuaternion(quat.x, quat.y, quat.z, -quat.w),
                            aroundTarget: SCNVector3(0, 0, 0))
        }
    }
}
