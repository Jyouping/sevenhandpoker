//
//  GameWinLoseView.swift
//  Seven Hand Poker
//
//  View for displaying win/lose panel with Play Again and Main Menu buttons
//

import SpriteKit

protocol GameWinLoseDelegate: AnyObject {
    func gameWinLosePlayAgain()
    func gameWinLoseMainMenu()
}

class GameWinLoseView: SKNode {

    weak var delegate: GameWinLoseDelegate?

    private var backgroundOverlay: SKSpriteNode!
    private var panelSprite: SKSpriteNode!
    private var playAgainButton: SKSpriteNode!
    private var mainMenuButton: SKSpriteNode!

    // Panel dimensions (based on actual image)
    private let panelWidth: CGFloat = 264
    private let panelHeight: CGFloat = 300
    private let panelScale: CGFloat = 2.0

    init(sceneSize: CGSize, isWin: Bool) {
        super.init()

        self.zPosition = 1000
        self.isUserInteractionEnabled = true

        setupOverlay(sceneSize: sceneSize)
        setupPanel(sceneSize: sceneSize, isWin: isWin)
        setupButtons()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupOverlay(sceneSize: CGSize) {
        backgroundOverlay = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.6), size: sceneSize)
        backgroundOverlay.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        backgroundOverlay.zPosition = 0
        addChild(backgroundOverlay)
    }

    private func setupPanel(sceneSize: CGSize, isWin: Bool) {
        let imageName = isWin ? "panel_win" : "panel_lose"
        panelSprite = SKSpriteNode(imageNamed: imageName)
        panelSprite.setScale(panelScale)
        panelSprite.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        panelSprite.zPosition = 1
        addChild(panelSprite)
    }

    private func setupButtons() {
        // Button positions relative to panel center (scaled)
        // Based on the image layout:
        // - "PLAY AGAIN" button is roughly at y = -70 from center
        // - "MAIN MENU" button is roughly at y = -115 from center

        // Play Again button
        playAgainButton = SKSpriteNode(imageNamed: "play_again_btn")
        playAgainButton.position = CGPoint(x: 0, y: -70)
        playAgainButton.zPosition = 2
        playAgainButton.name = "playAgainBtn"
        panelSprite.addChild(playAgainButton)

        // Main Menu button
        mainMenuButton = SKSpriteNode(imageNamed: "main_menu_btn")
        mainMenuButton.position = CGPoint(x: 0, y: -115)
        mainMenuButton.zPosition = 2
        mainMenuButton.name = "mainMenuBtn"
        panelSprite.addChild(mainMenuButton)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let panelLocation = touch.location(in: panelSprite)

        if playAgainButton.contains(panelLocation) {
            playAgainButton.alpha = 0.8
        } else if mainMenuButton.contains(panelLocation) {
            mainMenuButton.alpha = 0.8
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        panelSprite.alpha = 1.0

        guard let touch = touches.first else { return }
        let panelLocation = touch.location(in: panelSprite)

        if playAgainButton.contains(panelLocation) {
            delegate?.gameWinLosePlayAgain()
        } else if mainMenuButton.contains(panelLocation) {
            delegate?.gameWinLoseMainMenu()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        panelSprite.alpha = 1.0
    }
}
