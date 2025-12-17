//
//  MainMenuScene.swift
//  Seven Hand Poker
//
//  Main menu scene with Start and Settings buttons
//

import SpriteKit

class MainMenuScene: SKScene, SpinButtonDelegate, SettingViewDelegate {
    private var soundMgr: SoundMgr!

    private var backgroundNode: SKSpriteNode!
    private var titleNode: SKSpriteNode!
    private var startButton: SpinButton!
    private var instructionButton: SpinButton!
    private var settingsButton: SKSpriteNode!
    private var soundButton: SKSpriteNode!

    private var settingView: SettingView?



    class func newMenuScene() -> MainMenuScene {
        let scene = MainMenuScene(size: CGSize(width: 1400, height: 640))
        scene.scaleMode = .aspectFit
        return scene
    }

    override func didMove(to view: SKView) {
        setupBackground()
        setupButtons()
        setupMusic()
    }

    private func setupMusic() {
        soundMgr = SoundMgr.shared
        soundMgr.setScene(self)
        soundMgr.playBackgroundMusic()
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
        startButton = SpinButton(buttonImage: "play_btn", ringImage: "play_btn_ring", identifier: "play_button", size: CGSize(width: 120, height: 120), ringOffset: 35)
        startButton.position = CGPoint(x: size.width / 2 + 360, y: size.height / 2 - 120)
        startButton.name = "play_button"
        startButton.delegate = self
        startButton.setEnabled(true)
        addChild(startButton)
        
        // tutorial button
        instructionButton = SpinButton(buttonImage: "instruction_btn", ringImage: "instruction_btn_ring", identifier: "instruction_button", size: CGSize(width: 90, height: 90), ringOffset: 25)
        instructionButton.position = CGPoint(x: size.width / 2 + 230, y: size.height / 2 - 220)
        instructionButton.name = "instruction_button"
        instructionButton.delegate = self
        instructionButton.setEnabled(true)
        addChild(instructionButton)

        // Settings button
        soundButton = createButton(imagedName: "sound_on_icon", width: 150, height: 150)
        soundButton.position = CGPoint(x: 0, y: 0)
        soundButton.name = "soundButton"
        addChild(soundButton)
        
        settingsButton = createButton(imagedName: "setting_icon", width: 150, height: 150)
        settingsButton.position = CGPoint(x: 150, y: 0)
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

    // MARK: - Touch Handling

    func spinButtonClicked(_ button: SpinButton) {
        switch button.identifier {
        case "play_button":
            // 處理 play 按鈕
            goToGame()
            break
        case "instruction_button":
            goToInstruction()
            break
        default:
            break
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        for node in touchedNodes {
            if node.name == "soundButton" || node.parent?.name == "soundButton" {
                soundButton.alpha = 0.7
            }
            if node.name == "settingsButton" || node.parent?.name == "settingsButton" {
                settingsButton.alpha = 0.7
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)

        startButton.alpha = 1.0
        soundButton.alpha = 1.0
        settingsButton.alpha = 1.0

        for node in touchedNodes {
            if node.name == "soundButton" || node.parent?.name == "soundButton" {
                changeSound()
            }
            if node.name == "settingsButton" || node.parent?.name == "settingsButton" {
                openSettings()
            }
        }
    }

    // MARK: - Navigation

    private func goToGame() {
        let gameScene = GameScene.newGameScene(isTutorial: false)
        gameScene.scaleMode = .aspectFit
        soundMgr.stopBackgroundMusic()

        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(gameScene, transition: transition)
    }
    
    private func goToInstruction() {
        let gameScene = GameScene.newGameScene(isTutorial: true)
        gameScene.scaleMode = .aspectFit
        soundMgr.stopBackgroundMusic()

        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(gameScene, transition: transition)
    }

    private func changeSound() {
        if (soundMgr.enable) {
            soundMgr.disable()
            soundButton.texture = SKTexture(imageNamed: "sound_off_icon")
        } else {
            soundMgr.enable = true
            soundMgr.playBackgroundMusic()
            soundButton.texture = SKTexture(imageNamed: "sound_on_icon")
        }
    }
    private func openSettings() {
        // Remove existing setting view if any
        settingView?.removeFromParent()

        // Create and show setting view
        settingView = SettingView(sceneSize: size)
        settingView?.delegate = self
        addChild(settingView!)
    }

    // MARK: - SettingViewDelegate

    func settingViewDidDismiss() {
        settingView = nil
    }
}
