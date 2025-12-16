//
//  HeadFigure.swift
//  Seven Hand Poker
//
//  Player head figure display using SpriteKit
//

import SpriteKit

protocol HeadFigureDelegate: AnyObject {
    func headFigureClicked(_ headFigure: HeadFigure)
}

class HeadFigure: SKSpriteNode {
    static let slide_in_width: CGFloat = 300
    // MARK: - Properties

    private var _player: Int = 0
    private var _state: Int = 0
    private var _headOut: Bool = false
    private var _clickEnable: Bool = false

    private var headSprite: SKSpriteNode!
    private var ringSprite: SKSpriteNode!
    private var nameLabel: SKLabelNode!

    weak var delegate: HeadFigureDelegate?

    // Head figure states
    enum FigureState: Int {
        case sad = 1
        case slightlySad = 2
        case normal = 0
        case slightlyHappy = 3
        case happy = 4
    }

    // Animation states
    enum AnimationState: Int {
        case myTurn = 0
        case hidden = 1
        case deciding = 2
    }

    // MARK: - Initializer

    init(player: Int) {
        // Initialize as a transparent container sprite
        super.init(texture: nil, color: .clear, size: CGSize(width: 170, height: 190))

        _player = player
        _state = 0
        _headOut = false
        _clickEnable = false

        setupHead()
        setupRing()
        setupNameLabel()

        isUserInteractionEnabled = true
        changeFigure(.normal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupHead() {
        // Initialize with empty sprite, changeFigure will set the texture
        headSprite = SKSpriteNode()
        headSprite.size = CGSize(width: 160, height: 160)
        headSprite.position = CGPoint(x: 0, y: 10)
        headSprite.zPosition = 10
        headSprite.name = "head"
        addChild(headSprite)
    }

    private func setupRing() {
        ringSprite = SKSpriteNode(imageNamed: "submit_btn_ring")
        ringSprite.size = CGSize(width: 190, height: 190)
        ringSprite.position = CGPoint(x: 0, y: 0)
        ringSprite.zPosition = 5
        ringSprite.name = "ring"
        ringSprite.isHidden = true
        addChild(ringSprite)
    }

    private func setupNameLabel() {
        nameLabel = SKLabelNode(fontNamed: "MarkerFelt-Thin")
        nameLabel.fontSize = 18
        nameLabel.fontColor = .white
        nameLabel.horizontalAlignmentMode = .center
        nameLabel.verticalAlignmentMode = .top
        nameLabel.position = CGPoint(x: 0, y: -50)
        nameLabel.zPosition = 3
        nameLabel.name = "nameLabel"
        addChild(nameLabel)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if _clickEnable {
            // Visual feedback
            headSprite.alpha = 0.7
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        headSprite.alpha = 1.0
        if _clickEnable {
            delegate?.headFigureClicked(self)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        headSprite.alpha = 1.0
    }

    // MARK: - Public Methods

    func setName(_ name: String) {
        nameLabel.text = name
    }

    func getName() -> String {
        return nameLabel.text ?? ""
    }

    func getPlayer() -> Int {
        return _player
    }

    private func setClickEnable(_ enable: Bool) {
        // Only player1 can be clicked
        if _player != PlayerType.player2.rawValue {
            _clickEnable = enable
            isUserInteractionEnabled = enable
        }
    }

    func isClickEnabled() -> Bool {
        return _clickEnable
    }

    // MARK: - Ring Spin Animation

    func showSpin(_ show: Bool) {
        if show {
            ringSprite.isHidden = false
            startSpinAnimation()
            setClickEnable(true)
        } else {
            ringSprite.isHidden = true
            setClickEnable(false)
            ringSprite.removeAction(forKey: "spin")
        }
    }

    func startSpinAnimation() {
        ringSprite.removeAction(forKey: "spin")
        let rotateAction = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 4.0)
        let repeatAction = SKAction.repeatForever(rotateAction)
        ringSprite.run(repeatAction, withKey: "spin")
    }

    func stopSpinAnimation() {
        ringSprite.removeAction(forKey: "spin")
        ringSprite.isHidden = true
    }

    // MARK: - Figure State (Expression)

    func changeFigure(_ state: FigureState) {
        // The sprite sheet contains 5 expressions, each 200px wide
        // Layout: sad(0) | slightlySad(200) | normal(400) | slightlyHappy(600) | happy(800)
        // Total width: 1000px, height: 200px

        let imageName = _player == PlayerType.player1.rawValue ? "cat_head" : "dog_head"
        let spriteSheet = SKTexture(imageNamed: imageName)

        // Calculate the x offset based on state (normalized 0.0 - 1.0)
        // Each frame is 1/5 = 0.2 of total width
        let frameWidth: CGFloat = 0.2
        var xOffset: CGFloat

        switch state {
        case .sad:
            xOffset = 0.0      // First frame (x=0)
        case .slightlySad:
            xOffset = 0.2      // Second frame (x=200)
        case .normal:
            xOffset = 0.4      // Third frame (x=400)
        case .slightlyHappy:
            xOffset = 0.6      // Fourth frame (x=600)
        case .happy:
            xOffset = 0.8      // Fifth frame (x=800)
        }

        // Create texture from sprite sheet region
        // rect is in unit coordinate space (0.0 - 1.0)
        // Note: SKTexture y-axis is flipped (0 is bottom)
        let textureRect = CGRect(x: xOffset, y: 0, width: frameWidth, height: 1.0)
        let frameTexture = SKTexture(rect: textureRect, in: spriteSheet)

        headSprite.texture = frameTexture
    }

    // MARK: - Animation State (Slide In/Out)

    func changeAnimationState(_ state: AnimationState) {
        _state = state.rawValue
        let distMult: CGFloat = (_player == PlayerType.player1.rawValue) ? 1 : -1

        switch state {
        case .myTurn:
            if !_headOut {
                slideIn(distance: HeadFigure.slide_in_width * distMult, duration: 0.8)
            }
            _headOut = true

        case .hidden:
            setClickEnable(false)
            if _headOut {
                slideOut(distance: -HeadFigure.slide_in_width * distMult, duration: 0.8)
            }
            _headOut = false

        case .deciding:
            // Stay in current position
            break
        }
    }

    // MARK: - Slide Animations

    private func slideIn(distance: CGFloat, duration: TimeInterval) {
        let moveAction = SKAction.moveBy(x: distance, y: 0, duration: duration)
        moveAction.timingMode = .easeOut
        run(moveAction, withKey: "slide")
    }

    private func slideOut(distance: CGFloat, duration: TimeInterval) {
        let moveAction = SKAction.moveBy(x: distance, y: 0, duration: duration)
        moveAction.timingMode = .easeOut
        run(moveAction, withKey: "slide")
    }

    // MARK: - Convenience Methods

    func showAsActive() {
        showSpin(true)
        changeAnimationState(.myTurn)
    }

    func showAsInactive() {
        showSpin(false)
        changeAnimationState(.hidden)
    }

    func showWinExpression() {
        changeFigure(.happy)
        // Add a little bounce animation
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
        let bounce = SKAction.sequence([scaleUp, scaleDown])
        headSprite.run(bounce)
    }

    func showLoseExpression() {
        changeFigure(.sad)
        // Add a little shake animation
        let shakeLeft = SKAction.moveBy(x: -5, y: 0, duration: 0.05)
        let shakeRight = SKAction.moveBy(x: 10, y: 0, duration: 0.1)
        let shakeBack = SKAction.moveBy(x: -5, y: 0, duration: 0.05)
        let shake = SKAction.sequence([shakeLeft, shakeRight, shakeBack])
        let repeatShake = SKAction.repeat(shake, count: 3)
        headSprite.run(repeatShake)
    }

    func resetExpression() {
        changeFigure(.normal)
    }
}
