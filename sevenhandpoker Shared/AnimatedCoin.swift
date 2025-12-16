//
//  AnimatedCoin.swift
//  Seven Hand Poker
//
//  Reusable animated coin component using sprite sheet
//

import SpriteKit

class AnimatedCoin: SKSpriteNode {

    private var animationFrames: [SKTexture] = []
    private let frameCount = 8
    private let frameWidth: CGFloat = 100

    // Random playback settings
    private var randomPlaybackEnabled = false
    private var minInterval: TimeInterval = 2.0
    private var maxInterval: TimeInterval = 5.0
    private var playbackStartFrame: Int = 0
    private var playbackEndFrame: Int = 7
    private var playbackResetFrame: Int = 0

    init() {
        // Initialize with first frame
        let texture = AnimatedCoin.loadFrames(frameCount: 8, frameWidth: 100).first ?? SKTexture()
        super.init(texture: texture, color: .clear, size: CGSize(width: 100, height: 100))

        self.animationFrames = AnimatedCoin.loadFrames(frameCount: frameCount, frameWidth: frameWidth)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Static Frame Loader

    private static func loadFrames(frameCount: Int, frameWidth: CGFloat) -> [SKTexture] {
        guard let image = UIImage(named: "coin_animate"),
              let cgImage = image.cgImage else {
            return []
        }

        var frames: [SKTexture] = []
        let imageHeight = CGFloat(cgImage.height)
        let scale = image.scale

        for i in 0..<frameCount {
            let x = CGFloat(i) * frameWidth * scale
            let rect = CGRect(x: x, y: 0, width: frameWidth * scale, height: imageHeight)

            if let croppedImage = cgImage.cropping(to: rect) {
                let texture = SKTexture(cgImage: croppedImage)
                texture.filteringMode = .nearest
                frames.append(texture)
            }
        }

        return frames
    }

    // MARK: - Animation Methods

    /// Set to a specific frame
    func setFrame(_ frame: Int) {
        let frameIndex = max(0, min(frame, frameCount - 1))
        guard !animationFrames.isEmpty else { return }
        texture = animationFrames[frameIndex]
    }

    /// Play animation once (all frames)
    func playOnce(duration: TimeInterval = 0.8, completion: (() -> Void)? = nil) {
        guard !animationFrames.isEmpty else {
            completion?()
            return
        }

        let animation = SKAction.animate(with: animationFrames, timePerFrame: duration / Double(frameCount))

        if let completion = completion {
            run(SKAction.sequence([animation, SKAction.run(completion)]))
        } else {
            run(animation)
        }
    }

    /// Play animation once with specific frame range
    /// - Parameters:
    ///   - start: First frame index
    ///   - end: Last frame index
    ///   - duration: Total animation duration
    ///   - resetToFrame: Frame to return to after animation (nil = stay at last frame)
    ///   - completion: Callback after animation finishes
    func playOnce(fromFrame start: Int, toFrame end: Int, duration: TimeInterval = 0.4, resetToFrame: Int? = nil, completion: (() -> Void)? = nil) {
        let startIndex = max(0, min(start, frameCount - 1))
        let endIndex = max(startIndex, min(end, frameCount - 1))

        guard !animationFrames.isEmpty, startIndex <= endIndex else {
            completion?()
            return
        }

        let frames = Array(animationFrames[startIndex...endIndex])
        let animation = SKAction.animate(with: frames, timePerFrame: duration / Double(frames.count))

        var actions: [SKAction] = [animation]

        // Reset to specific frame if requested
        if let resetFrame = resetToFrame, resetFrame >= 0, resetFrame < frameCount {
            let resetAction = SKAction.setTexture(animationFrames[resetFrame])
            actions.append(resetAction)
        }

        if let completion = completion {
            actions.append(SKAction.run(completion))
        }

        run(SKAction.sequence(actions))
    }

    /// Play only the last 4 frames (frames 4-7), then return to frame 0
    func playLastFourFrames(duration: TimeInterval = 0.4, completion: (() -> Void)? = nil) {
        playOnce(fromFrame: 4, toFrame: 7, duration: duration, resetToFrame: 0, completion: completion)
    }

    /// Play animation in a loop
    func playLoop(duration: TimeInterval = 0.8) {
        guard !animationFrames.isEmpty else { return }

        let animation = SKAction.animate(with: animationFrames, timePerFrame: duration / Double(frameCount))
        let loop = SKAction.repeatForever(animation)
        run(loop, withKey: "coinLoop")
    }

    /// Stop looping animation
    func stopLoop() {
        removeAction(forKey: "coinLoop")
    }

    /// Play animation a specific number of times
    func play(times: Int, duration: TimeInterval = 0.8, completion: (() -> Void)? = nil) {
        guard !animationFrames.isEmpty, times > 0 else {
            completion?()
            return
        }

        let animation = SKAction.animate(with: animationFrames, timePerFrame: duration / Double(frameCount))
        let repeated = SKAction.repeat(animation, count: times)

        if let completion = completion {
            run(SKAction.sequence([repeated, SKAction.run(completion)]))
        } else {
            run(repeated)
        }
    }

    // MARK: - Random Playback

    /// Start random playback with configurable intervals
    /// - Parameters:
    ///   - minInterval: Minimum seconds between animations
    ///   - maxInterval: Maximum seconds between animations
    ///   - startFrame: First frame to play (default 4 for last 4 frames)
    ///   - endFrame: Last frame to play (default 7)
    ///   - resetFrame: Frame to return to after animation (default 0)
    func startRandomPlayback(minInterval: TimeInterval = 2.0,
                              maxInterval: TimeInterval = 5.0,
                              startFrame: Int = 4,
                              endFrame: Int = 7,
                              resetFrame: Int = 0) {
        self.minInterval = minInterval
        self.maxInterval = maxInterval
        self.playbackStartFrame = startFrame
        self.playbackEndFrame = endFrame
        self.playbackResetFrame = resetFrame
        self.randomPlaybackEnabled = true

        scheduleNextRandomPlay()
    }

    /// Stop random playback
    func stopRandomPlayback() {
        randomPlaybackEnabled = false
        removeAction(forKey: "randomPlayback")
    }

    private func scheduleNextRandomPlay() {
        guard randomPlaybackEnabled else { return }

        let randomDelay = TimeInterval.random(in: minInterval...maxInterval)

        let waitAction = SKAction.wait(forDuration: randomDelay)
        let playAction = SKAction.run { [weak self] in
            guard let self = self, self.randomPlaybackEnabled else { return }
            self.playOnce(fromFrame: self.playbackStartFrame, toFrame: self.playbackEndFrame, resetToFrame: self.playbackResetFrame) {
                self.scheduleNextRandomPlay()
            }
        }

        run(SKAction.sequence([waitAction, playAction]), withKey: "randomPlayback")
    }
}
