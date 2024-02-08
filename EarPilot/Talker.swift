//
//  Talker.swift
//  EarPilot
//
//  Created by Rogers George on 2/4/24.
//

import Foundation
import AVFoundation

class Talker {

    enum Position: CaseIterable {
        case left
        case right
        case center
    }

    let synth = AVSpeechSynthesizer()
    static let voice = AVSpeechSynthesisVoice(identifier: AVSpeechSynthesisVoiceIdentifierAlex)!

    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    let mixer = AVAudioEnvironmentNode()

    init() {
        let sess = AVAudioSession.sharedInstance()
        try! sess.setCategory(AVAudioSession.Category.playback,
                              mode: .voicePrompt)
        try! sess.setActive(true)

        engine.attach(mixer)
        engine.connect(mixer, to: engine.outputNode, format: nil)
        engine.attach(player)

        mixer.listenerPosition = .init(x: 0, y: 0, z: 0)
        mixer.reverbParameters.enable = true
        mixer.reverbParameters.loadFactoryReverbPreset(.largeHall)
        mixer.reverbParameters.level = -20
        mixer.renderingAlgorithm = .HRTFHQ
        player.reverbBlend = 0.4

        try! engine.start()
    }

    func speak(_ str: String, _ position: Position = Position.allCases.randomElement()!) {
        let utterance = AVSpeechUtterance(string: str + ".")
        utterance.voice = Self.voice
        utterance.rate = 0.65

        player.stop()

        switch(position) {
        case .left:
            player.position = .init(x: -1, y: 0, z: 0)
        case .right:
            player.position = .init(x: 1, y: 0, z: 0)
        case .center:
            player.position = .init(x: 0, y: 0, z: -1)
        }

        synth.write(utterance) { [self] buf in
            if engine.outputConnectionPoints(for: player, outputBus: 0).isEmpty {
                engine.connect(player, to: mixer, format: buf.format)
            }
            player.scheduleBuffer(buf as! AVAudioPCMBuffer)
            player.play()
        }
    }
}
