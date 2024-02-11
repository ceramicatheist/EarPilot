//
//  ModelController.swift
//  EarPilot
//
//  Created by Rogers George on 2/11/24.
//

import Foundation
import Combine

class ModelController: ObservableObject {

    let tracker = PositionTracker()
    let talker = Talker()

    private lazy var sub1 = tracker.objectWillChange.sink { [weak self] in
        self?.objectWillChange.send()
    }

    init() {
        _ = sub1
    }
}
