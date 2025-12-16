//
//  MainMenuScene.swift
//  Seven Hand Poker
//
//  Main menu scene with Start and Settings buttons
//

import SpriteKit

class MainMenuScene: SKScene, SpinButtonDelegate {

    private var backgroundNode: SKSpriteNode!
    private var titleNode: SKSpriteNode!
    private var startButton: SpinButton!
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
        titleNode = SKSpriteNode(imageNamed: "title")
        titleNode.position = CGPoint(x: size.width / 2 + 300, y: size.height / 2 + 120)
        titleNode.zPosition = 0
        addChild(titleNode)
    }

    
    private func setupButtons() {
        // Start button
        startButton = SpinButton(buttonImage: "play_btn", ringImage: "play_btn_ring", identifier: "play_button", size: CGSize(width: 120, height: 120))
        startButton.position = CGPoint(x: size.width / 2 + 300, y: size.height / 2 - 120)
        startButton.name = "play_button"
        startButton.delegate = self
        startButton.setEnabled(true)
        addChild(startButton)

        // Settings button
        settingsButton = createButton(imagedName: "setting_icon", width: 200, height: 200)
        settingsButton.position = CGPoint(x: 0, y: 0)
        settingsButton.name = "settingsButton"
        addChild(settingsButton)
    }

    private func createButton(imagedName: String, width: CGFloat, height: CGFloat) -> SKSpriteNode {
        let button = SKSpriteNode(imageNamed: imagedName)
        button.zPosition = 10
        //Note: this will update achor point to easier position - no animaion should be done here
        button.anchorPoint = CGPoint(x: 0, y: 0)
        button.size = CGSize(width: width, height: height)
        // Add rounded corner effect with border
        return button
    }

/*    // MARK: - Touch Handling

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
 */
    
    func spinButtonClicked(_ button: SpinButton) {
        switch button.identifier {
        case "play_button":
            // 處理 play 按鈕
            goToGame()
        default:
            break
        }
    }

/*

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

 */
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
