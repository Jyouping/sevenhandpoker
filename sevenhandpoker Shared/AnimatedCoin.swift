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

    /// Play animation once
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
}
