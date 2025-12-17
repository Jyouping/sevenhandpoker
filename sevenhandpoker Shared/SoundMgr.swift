//
//  SoundMgr.swift
//  Seven Hand Poker
//
//  Sound manager using SpriteKit's SKAudioNode
//

import SpriteKit

class SoundMgr {
    // MARK: - Properties

    private weak var scene: SKScene?

    private var bgMusicNode: SKAudioNode?

    var enable: Bool = true

    // MARK: - Singleton

    static let shared = SoundMgr()

    private init() {}

    // MARK: - Setup

    func setScene(_ scene: SKScene) {
        self.scene = scene
    }

    // MARK: - Background Music
    func disable() {
        stopBackgroundMusic()
        enable = false
    }

    func playBackgroundMusic() {
        guard enable, let scene = scene else { return }

        // Remove existing background music if any
        bgMusicNode?.removeFromParent()

        if let url = Bundle.main.url(forResource: "screen", withExtension: "mp3", subdirectory: "sounds") {
            bgMusicNode = SKAudioNode(url: url)
            bgMusicNode?.autoplayLooped = true
            if let node = bgMusicNode {
                scene.addChild(node)
            }
        } else if let url = Bundle.main.url(forResource: "screen", withExtension: "mp3") {
            bgMusicNode = SKAudioNode(url: url)
            bgMusicNode?.autoplayLooped = true
            if let node = bgMusicNode {
                scene.addChild(node)
            }
        }
    }

    func stopBackgroundMusic() {
        bgMusicNode?.removeFromParent()
        bgMusicNode = nil
    }

    // MARK: - Sound Effects

    func playTick() {
        playSound(filename: "poker3", ext: "mp3")
    }

    func playPlace() {
        playSound(filename: "poker4", ext: "mp3")
    }
    
    func playSelect() {
        playSound(filename: "Select", ext: "wav")
    }

    func playCompare() {
        playSound(filename: "compare", ext: "mp3")
    }

    func playSort() {
        playSound(filename: "flush", ext: "wav")
    }

    func playVictory() {
        playSound(filename: "Victory", ext: "wav")
    }

    func playLose() {
        playSound(filename: "Lose", ext: "mp3")
    }

    // MARK: - Private Helper

    private func playSound(filename: String, ext: String) {
        guard enable, let scene = scene else { return }

        // Try with subdirectory first
        let soundPath = "sounds/\(filename).\(ext)"
        if Bundle.main.url(forResource: filename, withExtension: ext, subdirectory: "sounds") != nil {
            scene.run(SKAction.playSoundFileNamed(soundPath, waitForCompletion: false))
        } else if Bundle.main.url(forResource: filename, withExtension: ext) != nil {
            // Fallback without subdirectory
            scene.run(SKAction.playSoundFileNamed("\(filename).\(ext)", waitForCompletion: false))
        } else {
            print("Sound file not found: \(filename).\(ext)")
        }
    }
}
