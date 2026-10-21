import AVFoundation
import SwiftUI

public enum AmbientSoundType: String, CaseIterable, Identifiable, Codable, Sendable {
    case rain = "Rain"
    case ocean = "Ocean Waves"
    case whiteNoise = "White Noise"
    case stream = "Gentle Stream"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .rain: return "cloud.rain.fill"
        case .ocean: return "water.waves"
        case .whiteNoise: return "wind"
        case .stream: return "leaf.fill"
        }
    }
}

@MainActor
public final class AmbientSoundService: ObservableObject {
    public static let shared = AmbientSoundService()
    
    @Published public private(set) var isPlaying = false
    @Published public private(set) var currentSound: AmbientSoundType = .rain
    @Published public var volume: Float = 0.5 {
        didSet {
            engine?.mainMixerNode.outputVolume = volume
        }
    }
    
    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    
    private init() {}
    
    public func toggleSound(_ type: AmbientSoundType) {
        if isPlaying && currentSound == type {
            stop()
        } else {
            play(type: type)
        }
    }
    
    public func play(type: AmbientSoundType) {
        stop()
        self.currentSound = type
        
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        
        engine.attach(player)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = volume
        
        guard let buffer = generateNoiseBuffer(type: type, format: format) else { return }
        
        do {
            try engine.start()
            player.play()
            player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            
            self.engine = engine
            self.playerNode = player
            self.isPlaying = true
        } catch {
            print("Failed to start ambient engine: \(error)")
        }
    }
    
    public func stop() {
        playerNode?.stop()
        engine?.stop()
        playerNode = nil
        engine = nil
        isPlaying = false
    }
    
    private nonisolated func generateNoiseBuffer(type: AmbientSoundType, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = 44100
        let durationSeconds = 3
        let frameCount = AVAudioFrameCount(sampleRate * durationSeconds)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else { return nil }
        
        var b0: Float = 0, b1: Float = 0, b2: Float = 0
        
        for i in 0..<Int(frameCount) {
            let white = Float.random(in: -1.0...1.0)
            let val: Float
            
            switch type {
            case .whiteNoise:
                val = white * 0.15
            case .rain:
                // Pink noise filter for rain
                b0 = 0.99886 * b0 + white * 0.0555179
                b1 = 0.99332 * b1 + white * 0.0750759
                b2 = 0.96900 * b2 + white * 0.1538520
                val = (b0 + b1 + b2) * 0.10
            case .ocean:
                // Low frequency oscillation modulated noise
                let t = Float(i) / Float(sampleRate)
                let swell = (sin(t * 1.2) + 1.0) * 0.5
                b0 = 0.99 * b0 + white * 0.08
                val = b0 * (0.05 + swell * 0.12)
            case .stream:
                b0 = 0.95 * b0 + white * 0.12
                val = b0 * 0.10
            }
            
            leftChannel[i] = val
            rightChannel[i] = val
        }
        
        return buffer
    }
}
