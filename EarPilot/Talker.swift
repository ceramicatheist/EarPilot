//
//  Talker.swift
//  EarPilot
//
//  Created by Rogers George on 2/4/24.
//

import AVFoundation
import Spatial
import SwiftUI

class Talker {

    let synth = AVSpeechSynthesizer()

    let voices: [AVSpeechSynthesisVoice] = {
        AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.starts(with: "en-") }
            .filter { !$0.voiceTraits.contains(.isNoveltyVoice) }
            .sorted { $1.language < $0.language /* prefer en-US to en-GB */ }
    }()

    @AppStorage("voice") var voiceIdentifier: String = ""

    var voice: AVSpeechSynthesisVoice? {
        get {
            var voice = voices.first { $0.identifier == self.voiceIdentifier }
            if voice == nil {
                voice = voices.first { $0.quality == .premium } ??
                voices.first { $0.quality == .enhanced } ??
                voices.first { $0.identifier == AVSpeechSynthesisVoiceIdentifierAlex } ??
                voices.first { $0.gender == .male } ??
                voices.first
                self.voiceIdentifier = voice?.identifier ?? ""
            }
            return voice
        }
        set {
            voiceIdentifier = newValue?.identifier ?? ""
        }
    }

    let engine = AVAudioEngine()
    let voicePlayers: [AVAudioPlayerNode] = [
        AVAudioPlayerNode(),
        AVAudioPlayerNode(),
        AVAudioPlayerNode(),
        AVAudioPlayerNode(),
        AVAudioPlayerNode(),
    ]
    var currentPlayer: Int = 0
    let mixer = AVAudioEnvironmentNode()
    let upBeeper = AVAudioUnitSampler()
    let levelBeeper = AVAudioUnitSampler()
    let downBeeper = AVAudioUnitSampler()

    init() {
        let sess = AVAudioSession.sharedInstance()
        try! sess.setCategory(AVAudioSession.Category.playback,
                              mode: .voicePrompt)
        try! sess.setActive(true)

        engine.attach(mixer)
        engine.connect(mixer, to: engine.outputNode, format: nil)
        voicePlayers.forEach { engine.attach($0) }
        engine.attach(upBeeper)
        upBeeper.sourceMode = .ambienceBed
        engine.attach(levelBeeper)
        levelBeeper.sourceMode = .ambienceBed
        engine.attach(downBeeper)
        downBeeper.sourceMode = .ambienceBed

        mixer.listenerPosition = .init(x: 0, y: 0, z: 0)
        mixer.renderingAlgorithm = .HRTFHQ

        let url = Bundle.main.url(forResource: "gs_instruments", withExtension: "dls")
        try! upBeeper.loadSoundBankInstrument(at: url!,
                                              program: 89,
                                              bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                              bankLSB: UInt8(kAUSampler_DefaultBankLSB))
        try! levelBeeper.loadSoundBankInstrument(at: url!,
                                                 program: 14,
                                                 bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                                 bankLSB: UInt8(kAUSampler_DefaultBankLSB))
        try! downBeeper.loadSoundBankInstrument(at: url!,
                                                program: 93,
                                                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                                bankLSB: UInt8(kAUSampler_DefaultBankLSB))
        try! engine.start()

        let utterance = AVSpeechUtterance(string: ".")
        utterance.voice = voice
        synth.write(utterance) { [self] buf in
            voicePlayers.forEach {
                engine.connect($0, to: mixer, format: buf.format)
            }
        }
    }

    /// angle is clockwise from 0 = straight ahead, just like flying
    func speak(_ str: String, _ angle: Angle2D = .zero) {
        if !engine.isRunning { try! engine.start() }
        let utterance = AVSpeechUtterance(string: str + ".")
        utterance.voice = voice
        utterance.rate = 0.65

        let voicePlayer = voicePlayers[currentPlayer]
        currentPlayer = (currentPlayer + 1) % voicePlayers.count
        voicePlayer.stop()
        voicePlayer.position = .init(x: Float(sin(angle.radians)), y: 0, z: -Float(cos(angle.radians)))

        synth.write(utterance) { [self] buf in
            if engine.outputConnectionPoints(for: voicePlayer, outputBus: 0).isEmpty {
                engine.connect(voicePlayer, to: mixer, format: buf.format)
            }
            voicePlayer.scheduleBuffer(buf as! AVAudioPCMBuffer)
            voicePlayer.play()
        }

    }

    func beep(_ pitch: Int) {
        if !engine.isRunning { try! engine.start() }
        if engine.outputConnectionPoints(for: upBeeper, outputBus: 0).isEmpty {
            engine.connect(upBeeper, to: mixer, format: upBeeper.outputFormat(forBus: 0))
        }
        if engine.outputConnectionPoints(for: levelBeeper, outputBus: 0).isEmpty {
            engine.connect(levelBeeper, to: mixer, format: levelBeeper.outputFormat(forBus: 0))
        }
        if engine.outputConnectionPoints(for: downBeeper, outputBus: 0).isEmpty {
            engine.connect(downBeeper, to: mixer, format: downBeeper.outputFormat(forBus: 0))
        }
        let note: UInt8 = UInt8(69 + pitch)
        if pitch > 0 {
            upBeeper.startNote(note, withVelocity: 64, onChannel: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [self] in
                upBeeper.stopNote(note, onChannel: 0)
            }
        }
        if pitch < 0 {
            downBeeper.startNote(note, withVelocity: 64, onChannel: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [self] in
                downBeeper.stopNote(note, onChannel: 0)
            }
        }
        if pitch == 0 {
            levelBeeper.startNote(note, withVelocity: 64, onChannel: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [self] in
                levelBeeper.stopNote(note, onChannel: 0)
            }
        }
    }
}

extension AVSpeechSynthesisVoice: Identifiable {
    public var id: String { identifier }
}
