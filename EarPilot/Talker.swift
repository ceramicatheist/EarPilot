//
//  Talker.swift
//  EarPilot
//
//  Created by Rogers George on 2/4/24.
//

import Foundation
import AVFoundation
import SwiftUI

class Talker {

    @AppStorage("speakEnabled") var shouldSpeak = true
    @AppStorage("beepEnabled") var shouldBeep = true

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
    let upBeeper = AVAudioUnitSampler()
    let downBeeper = AVAudioUnitSampler()

    init() {
        let sess = AVAudioSession.sharedInstance()
        try! sess.setCategory(AVAudioSession.Category.playback,
                              mode: .voicePrompt)
        try! sess.setActive(true)

        engine.attach(mixer)
        engine.connect(mixer, to: engine.outputNode, format: nil)
        engine.attach(voicePlayer)
        engine.attach(upBeeper)
        engine.attach(downBeeper)

        mixer.listenerPosition = .init(x: 0, y: 0, z: 0)
        mixer.renderingAlgorithm = .HRTFHQ

        let url = Bundle.main.url(forResource: "gs_instruments", withExtension: "dls")
        try! upBeeper.loadSoundBankInstrument(at: url!,
                                             program: 72,
                                             bankMSB: 0x79,
                                             bankLSB: 0)
        try! downBeeper.loadSoundBankInstrument(at: url!,
                                                program: 71,
                                                bankMSB: 0x79,
                                                bankLSB: 0)
        try! engine.start()
        speak(".")
    }

    func speak(_ str: String, _ position: Position = Position.allCases.randomElement()!) {
        guard shouldSpeak else {return}
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

    func beep(_ pitch: Int) {
        guard shouldBeep else {return}
        if !engine.isRunning { try! engine.start() }
        if engine.outputConnectionPoints(for: upBeeper, outputBus: 0).isEmpty {
            engine.connect(upBeeper, to: mixer, format: upBeeper.outputFormat(forBus: 0))
        }
        if engine.outputConnectionPoints(for: downBeeper, outputBus: 0).isEmpty {
            engine.connect(downBeeper, to: mixer, format: upBeeper.outputFormat(forBus: 0))
        }
        let note: UInt8 = UInt8(69 + pitch)
        if pitch >= 0 {
            upBeeper.startNote(note, withVelocity: 64, onChannel: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [self] in
                upBeeper.stopNote(note, onChannel: 0)
            }
        }
        if pitch <= 0 {
            downBeeper.startNote(note, withVelocity: 64, onChannel: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [self] in
                downBeeper.stopNote(note, onChannel: 0)
            }
        }
    }
}
