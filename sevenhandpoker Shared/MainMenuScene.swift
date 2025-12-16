//
//  MainMenuScene.swift
//  Seven Hand Poker
//
//  Main menu scene with Start and Settings buttons
//

import SpriteKit

class MainMenuScene: SKScene {

    private var backgroundNode: SKSpriteNode!
    private var startButton: SKSpriteNode!
    private var settingsButton: SKSpriteNode!

    class func newMenuScene() -> MainMenuScene {
        let scene = MainMenuScene(size: CGSize(width: 1400, height: 640))
        scene.scaleMode = .aspectFit
        return scene
    }

    override func didMove(to view: SKView) {
        setupBackground()
        setupButtons()
    }

    // MARK: - Setup

    private func setupBackground() {
        backgroundNode = SKSpriteNode(imageNamed: "main_menu_bg")
        backgroundNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode.zPosition = -1
        backgroundNode.size = size
        addChild(backgroundNode)
    }

    private func setupButtons() {
        // Start button
        startButton = createButton(text: "START", color: UIColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0))
        startButton.position = CGPoint(x: size.width / 2, y: size.height / 2)
        startButton.name = "startButton"
        addChild(startButton)

        // Settings button
        settingsButton = createButton(text: "SETTINGS", color: UIColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 1.0))
        settingsButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 100)
        settingsButton.name = "settingsButton"
        addChild(settingsButton)
    }

    private func createButton(text: String, color: UIColor) -> SKSpriteNode {
        let button = SKSpriteNode(color: color, size: CGSize(width: 200, height: 60))
        button.zPosition = 10

        // Add rounded corner effect with border
        let border = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 10)
        border.strokeColor = .white
        border.lineWidth = 3
        border.fillColor = .clear
        border.zPosition = 1
        button.addChild(border)

        let label = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        label.text = text
        label.fontSize = 28
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.zPosition = 2
        button.addChild(label)

        return button
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        for node in touchedNodes {
            if node.name == "startButton" || node.parent?.name == "startButton" {
                startButton.alpha = 0.7
            } else if node.name == "settingsButton" || node.parent?.name == "settingsButton" {
                settingsButton.alpha = 0.7
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        startButton.alpha = 1.0
        settingsButton.alpha = 1.0

        for node in touchedNodes {
            if node.name == "startButton" || node.parent?.name == "startButton" {
                goToGame()
            } else if node.name == "settingsButton" || node.parent?.name == "settingsButton" {
                openSettings()
            }
        }
    }

    // MARK: - Navigation

    private func goToGame() {
        let gameScene = GameScene.newGameScene()
        gameScene.scaleMode = .aspectFit

        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(gameScene, transition: transition)
    }

    private func openSettings() {
        // TODO: Implement settings scene
        print("Settings tapped")
    }
}
