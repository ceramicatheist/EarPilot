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
    let voicePlayer = AVAudioPlayerNode()
    let mixer = AVAudioEnvironmentNode()
    let beeper = AVAudioUnitSampler()

    init() {
        let sess = AVAudioSession.sharedInstance()
        try! sess.setCategory(AVAudioSession.Category.playback,
                              mode: .voicePrompt)
        try! sess.setActive(true)

        engine.attach(mixer)
        engine.connect(mixer, to: engine.outputNode, format: nil)
        engine.attach(voicePlayer)
        engine.attach(beeper)

        mixer.listenerPosition = .init(x: 0, y: 0, z: 0)
        mixer.renderingAlgorithm = .HRTFHQ

        let url = Bundle.main.url(forResource: "gs_instruments", withExtension: "dls")
        try! beeper.loadSoundBankInstrument(at: url!,
                                             program: 1,
                                             bankMSB: 0x79,
                                             bankLSB: 0)
        try! engine.start()
    }

    func speak(_ str: String, _ position: Position = Position.allCases.randomElement()!) {
        if !engine.isRunning { try! engine.start() }

        let utterance = AVSpeechUtterance(string: str + ".")
        utterance.voice = Self.voice
        utterance.rate = 0.65

        voicePlayer.stop()

        switch(position) {
        case .left:
            voicePlayer.position = .init(x: -1, y: 0, z: 0)
        case .right:
            voicePlayer.position = .init(x: 1, y: 0, z: 0)
        case .center:
            voicePlayer.position = .init(x: 0, y: 0, z: -1)
        }

        synth.write(utterance) { [self] buf in
            if engine.outputConnectionPoints(for: voicePlayer, outputBus: 0).isEmpty {
                engine.connect(voicePlayer, to: mixer, format: buf.format)
            }
            voicePlayer.scheduleBuffer(buf as! AVAudioPCMBuffer)
            voicePlayer.play()
        }
    }

    func beep() {
        if !engine.isRunning { try! engine.start() }
        if engine.outputConnectionPoints(for: beeper, outputBus: 0).isEmpty {
            engine.connect(beeper, to: mixer, format: beeper.outputFormat(forBus: 0))
        }
        let note: UInt8 = .random(in: 32...96)
        beeper.startNote(note, withVelocity: 64, onChannel: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            beeper.stopNote(note, onChannel: 0)
        }
    }
}
