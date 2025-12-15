//
//  SoundMgr.swift
//  Seven Hand Poker
//
//  Converted to Swift from SoundMgr.h/m
//

import Foundation
import AVFoundation

class SoundMgr {
    // MARK: - Properties

    private var bgMusicPlayer: AVAudioPlayer?
    private var tickPlayer: AVAudioPlayer?
    private var selectPlayer: AVAudioPlayer?
    private var comparePlayer: AVAudioPlayer?
    private var sortPlayer: AVAudioPlayer?
    private var victoryPlayer: AVAudioPlayer?
    private var losePlayer: AVAudioPlayer?

    var enable: Bool = true

    // MARK: - Singleton

    nonisolated(unsafe) static let sharedInstance = SoundMgr()

    private init() {
        setupAudioPlayers()
    }

    // MARK: - Setup

    private func setupAudioPlayers() {
        bgMusicPlayer = createPlayer(filename: "screen", ext: "mp3")
        tickPlayer = createPlayer(filename: "poker2", ext: "mp3")
        selectPlayer = createPlayer(filename: "Select", ext: "wav")
        comparePlayer = createPlayer(filename: "compare", ext: "mp3")
        sortPlayer = createPlayer(filename: "flush", ext: "wav")
        victoryPlayer = createPlayer(filename: "Victory", ext: "wav")
        losePlayer = createPlayer(filename: "lose", ext: "mp3")

        bgMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
    }

    private func createPlayer(filename: String, ext: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else {
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            print("Error loading audio file: \(filename).\(ext)")
            return nil
        }
    }

    // MARK: - Playback Methods

    func playBackgroundMusic() {
        guard enable else { return }
        bgMusicPlayer?.play()
    }

    func stopBackgroundMusic() {
        bgMusicPlayer?.stop()
    }

    func playTick() {
        guard enable else { return }
        tickPlayer?.currentTime = 0
        tickPlayer?.play()
    }

    func playSelect() {
        guard enable else { return }
        selectPlayer?.currentTime = 0
        selectPlayer?.play()
    }

    func playCompare() {
        guard enable else { return }
        comparePlayer?.currentTime = 0
        comparePlayer?.play()
    }

    func playSort() {
        guard enable else { return }
        sortPlayer?.currentTime = 0
        sortPlayer?.play()
    }

    func playVictory() {
        guard enable else { return }
        victoryPlayer?.currentTime = 0
        victoryPlayer?.play()
    }

    func playLose() {
        guard enable else { return }
        losePlayer?.currentTime = 0
        losePlayer?.play()
    }
}
