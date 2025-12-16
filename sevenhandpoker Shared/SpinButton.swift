//
//  SpinButton.swift
//  Seven Hand Poker
//
//  Custom button with spinning ring animation
//

import SpriteKit

protocol SpinButtonDelegate: AnyObject {
    func spinButtonClicked(_ button: SpinButton)
}

class SpinButton: SKSpriteNode {

    weak var delegate: SpinButtonDelegate?

    private var buttonSprite: SKSpriteNode!
    private var ringSprite: SKSpriteNode!

    private var isEnabled: Bool = false
    private var isClickable: Bool = false

    // Button identifier for distinguishing different buttons
    private(set) var identifier: String = ""

    // Spin animation settings
    var spinDuration: TimeInterval = 4.0

    /// Initialize with button and ring image names
    /// - Parameters:
    ///   - buttonImage: Name of the button image asset
    ///   - ringImage: Name of the ring image asset
    ///   - identifier: Unique identifier for this button
    ///   - size: Optional size for both button and ring (nil = use original image size)
    init(buttonImage: String, ringImage: String, identifier: String = "", size: CGSize? = nil) {
        super.init(texture: nil, color: .clear, size: size ?? CGSize(width: 100, height: 100))

        self.identifier = identifier
        self.isUserInteractionEnabled = true

        setupButton(buttonImage: buttonImage, ringImage: ringImage, size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupButton(buttonImage: String, ringImage: String, size: CGSize?) {
        // Button sprite (base)
        buttonSprite = SKSpriteNode(imageNamed: buttonImage)
        buttonSprite.zPosition = 0
        addChild(buttonSprite)

        // Ring sprite (rotating overlay)
        ringSprite = SKSpriteNode(imageNamed: ringImage)
        ringSprite.zPosition = 1
        ringSprite.isHidden = true
        addChild(ringSprite)

        // Set size
        if let size = size {
            setSize(size)
        } else {
            self.size = buttonSprite.size
            ringSprite.size = CGSize(width: buttonSprite.size.width + 30, height: buttonSprite.size.height + 30)
        }
    }

    // MARK: - Public Methods

    /// Set button enabled state
    /// When enabled, ring appears and spins; when disabled, ring disappears
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled

        if enabled {
            ringSprite.isHidden = false
            startSpinAnimation()
            isClickable = true
        } else {
            ringSprite.isHidden = true
            stopSpinAnimation()
            isClickable = false
        }
    }

    /// Check if button is enabled
    func getEnabled() -> Bool {
        return isEnabled
    }

    /// Set size for both button and ring
    func setSize(_ size: CGSize) {
        self.size = size
        buttonSprite.size = size
        ringSprite.size = CGSize(width: size.width + 30, height: size.height + 30)
    }

    /// Change button image
    func setButtonImage(_ imageName: String) {
        buttonSprite.texture = SKTexture(imageNamed: imageName)
    }

    /// Change ring image
    func setRingImage(_ imageName: String) {
        ringSprite.texture = SKTexture(imageNamed: imageName)
    }

    // MARK: - Spin Animation

    private func startSpinAnimation() {
        ringSprite.removeAction(forKey: "spin")
        // Clockwise rotation (negative angle)
        let rotateAction = SKAction.rotate(byAngle: -CGFloat.pi * 2, duration: spinDuration)
        let repeatAction = SKAction.repeatForever(rotateAction)
        ringSprite.run(repeatAction, withKey: "spin")
    }

    private func stopSpinAnimation() {
        ringSprite.removeAction(forKey: "spin")
        ringSprite.zRotation = 0
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("SpinButton touchesBegan - isClickable: \(isClickable)")
        guard isClickable else { return }
        buttonSprite.alpha = 0.7
        ringSprite.alpha = 0.7
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("SpinButton touchesEnded - isClickable: \(isClickable), delegate: \(String(describing: delegate))")
        guard isClickable else { return }

        buttonSprite.alpha = 1.0
        ringSprite.alpha = 1.0

        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Check if touch ended within button bounds (relative to center anchor)
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        let hitRect = CGRect(x: -halfWidth, y: -halfHeight, width: size.width, height: size.height)

        print("SpinButton touch location: \(location), hitRect: \(hitRect), contains: \(hitRect.contains(location))")

        if hitRect.contains(location) {
            print("SpinButton calling delegate")
            delegate?.spinButtonClicked(self)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        buttonSprite.alpha = 1.0
        ringSprite.alpha = 1.0
    }
}
