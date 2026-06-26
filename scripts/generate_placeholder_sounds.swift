import AVFoundation
import Foundation

// Generates short placeholder SFX (sine-wave tones, distinct pitch per event) as bundled
// .caf files. Swap these for real sound-designed assets later — the filenames must match
// SoundEffect.rawValue so SoundCoordinator can find them by name without code changes.

let outputDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

struct ToneSpec { let name: String; let frequencies: [Double]; let durations: [Double] }

let specs: [ToneSpec] = [
    ToneSpec(name: "cardPlay",      frequencies: [660],                 durations: [0.08]),
    ToneSpec(name: "cardDraw",      frequencies: [440],                 durations: [0.07]),
    ToneSpec(name: "cardShuffle",   frequencies: [330, 392, 440],       durations: [0.05, 0.05, 0.05]),
    ToneSpec(name: "skipPlayed",    frequencies: [523, 392],            durations: [0.06, 0.06]),
    ToneSpec(name: "reversePlayed", frequencies: [392, 523],            durations: [0.06, 0.06]),
    ToneSpec(name: "drawTwoPlayed", frequencies: [440, 440],            durations: [0.06, 0.06]),
    ToneSpec(name: "wildPlayed",    frequencies: [523, 659, 784],       durations: [0.05, 0.05, 0.08]),
    ToneSpec(name: "soloCall",      frequencies: [784, 988],            durations: [0.07, 0.12]),
    ToneSpec(name: "soloMissed",    frequencies: [392, 330],            durations: [0.10, 0.15]),
    ToneSpec(name: "roundWin",      frequencies: [523, 659, 784, 1046], durations: [0.08, 0.08, 0.08, 0.18]),
    ToneSpec(name: "gameWin",       frequencies: [523, 659, 784, 1046, 1318], durations: [0.08, 0.08, 0.08, 0.10, 0.25]),
    ToneSpec(name: "buttonTap",     frequencies: [880],                 durations: [0.04]),
    ToneSpec(name: "cardFan",       frequencies: [600, 650, 700],       durations: [0.03, 0.03, 0.03]),
    ToneSpec(name: "swapHands",     frequencies: [440, 554, 440],       durations: [0.06, 0.06, 0.06]),
]

let sampleRate = 44100.0

func synthesize(frequencies: [Double], durations: [Double]) -> AVAudioPCMBuffer {
    let frameCounts = durations.map { Int($0 * sampleRate) }
    let totalFrames = AVAudioFrameCount(frameCounts.reduce(0, +))
    let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames)!
    buffer.frameLength = totalFrames
    let data = buffer.floatChannelData![0]

    var frameOffset = 0
    for (freq, frameCount) in zip(frequencies, frameCounts) {
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            let progress = Double(i) / Double(max(frameCount, 1))
            // short attack/release envelope to avoid clicks at tone boundaries
            let envelope = min(1.0, progress * 20) * min(1.0, (1.0 - progress) * 20)
            let sample = sin(2.0 * .pi * freq * t) * 0.25 * envelope
            data[frameOffset + i] = Float(sample)
        }
        frameOffset += frameCount
    }
    return buffer
}

for spec in specs {
    let buffer = synthesize(frequencies: spec.frequencies, durations: spec.durations)
    let url = outputDir.appendingPathComponent("\(spec.name).caf")
    let file = try! AVAudioFile(
        forWriting: url,
        settings: buffer.format.settings,
        commonFormat: .pcmFormatFloat32,
        interleaved: false
    )
    try! file.write(from: buffer)
    print("wrote \(url.path)")
}
