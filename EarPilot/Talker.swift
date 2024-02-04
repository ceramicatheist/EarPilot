//
//  Talker.swift
//  EarPilot
//
//  Created by Rogers George on 2/4/24.
//

import Foundation
import Combine
import Spatial
import AVFoundation

class Talker: NSObject {

    var tracker: PositionTracker? {
        didSet {
            subscription = tracker?.$attitude.assign(to: \.attitude, on: self)
        }
    }

    private var subscription: AnyCancellable?

    private var timer: Timer?

    override init() {
        super.init()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            self.talk()
        }
    }

    private lazy var synth = {
        let synth = AVSpeechSynthesizer()
        synth.delegate = self
        return synth
    }()

    var attitude: Rotation3D = .identity

    func talk() {
        guard let tracker else {return}
        let text = abs(tracker.roll.degrees.rounded()).description
        print(text)
        let utt = AVSpeechUtterance(string: text)
        utt.voice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.enhanced.en-US.Evan")
        synth.speak(utt)
    }
}

extension Talker: AVSpeechSynthesizerDelegate {

}
